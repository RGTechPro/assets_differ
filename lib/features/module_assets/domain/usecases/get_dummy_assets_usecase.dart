import 'dart:convert';
import 'dart:typed_data';

import 'package:assets_differ/core/models/dynamic_asset_url.dart';
import 'package:assets_differ/core/utils/performance_tracker.dart';
import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/ensure_zero_pixel_image_exists_usecase.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/manifest_compare_usecase.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/version_compare_usecase.dart';
import 'package:assets_differ/core/logging.dart';

/// Coordinator UseCase to provide and manage DummyAssets
/// Delegates specific tasks to specialized usecases
class GetDummyAssetsUseCase<T> {
  final DummyDataRepository _repository;
  final ManifestCompareUseCase _manifestCompareUseCase;
  final VersionCompareUseCase _versionCompareUseCase;
  final ZeroPixelImageDataGeneratorUsecase _zeroPixelImageDataGenerator;
  final String _currentVersion;
  final _logger = AssetLogger('GetDummyAssetsUseCase');

  final AssetMapper<T> _assetMapper;

  T get dummyAssets => _dummyAssets!;

  T? _dummyAssets;

  final zeroPixelPath = kZeroPixel.path;

  GetDummyAssetsUseCase({
    required DummyDataRepository repository,
    required ManifestCompareUseCase manifestCompareUseCase,
    required AssetMapper<T> assetMapper,
    required VersionCompareUseCase versionCompareUseCase,
    required ZeroPixelImageDataGeneratorUsecase zeroPixelImageDataGenerator,
    required String currentVersion,
  })  : _currentVersion = currentVersion,
        _repository = repository,
        _manifestCompareUseCase = manifestCompareUseCase,
        _assetMapper = assetMapper,
        _versionCompareUseCase = versionCompareUseCase,
        _zeroPixelImageDataGenerator = zeroPixelImageDataGenerator;

  Future<void> _generateZeroPixelImage() async {
    try {
      final Uint8List? zeroAssetPath =
          await _repository.getAssetByPath(zeroPixelPath);
      if (zeroAssetPath != null) {
        _logger.info('Zero pixel image already exists');
        PerformanceTracker.endTracking(
            'EnsureZeroPixelImageExistsUseCase.execute');
        return;
      }
    } catch (e) {
      // Image doesn't exist - we'll create it
      _logger.info('Zero pixel image not found - will generate');
    }

    // First ensure that the zero pixel placeholder image exists
    final uint8List = await _zeroPixelImageDataGenerator.execute();

    // Save to repository
    final result = await _saveUint8Image(
      assetPath: zeroPixelPath,
      imageBytes: uint8List,
    );

    if (result.isSuccess) {
      _logger.info('Zero pixel image saved successfully');
    } else {
      _logger.error('Failed to save zero pixel image');
    }
  }

  /// Execute the use case to get DummyAssets as an Observable
  Future<T> execute() async {
    if (_dummyAssets != null) {
      // If assets are already loaded, return them
      return _dummyAssets!;
    }

    _dummyAssets = _assetMapper.empty();

    await _generateZeroPixelImage();

    // Start tracking the entire execution
    PerformanceTracker.startTracking('GetDummyAssetsUseCase.execute');

    try {
      // First, load local manifest to get the current version
      PerformanceTracker.startTracking('getLocalManifest');
      final AssetManifest? localManifest = await _repository.getLocalManifest();
      PerformanceTracker.endTracking('getLocalManifest');

      if (localManifest == null) {
        // If no local manifest exists, we need to get everything from remote
        final result = await _handleMajorVersionChange();
        PerformanceTracker.endTracking('GetDummyAssetsUseCase.execute');
        return result;
      }

      // Check version differences using the dedicated usecase
      PerformanceTracker.startTracking('compareVersions');
      final VersionChange versionChange =
          _versionCompareUseCase.compareVersions(
        localManifest.version,
      );
      PerformanceTracker.endTracking('compareVersions');

      if (versionChange == VersionChange.major) {
        // For major version changes, use current implementation
        final result = await _handleMajorVersionChange();
        PerformanceTracker.endTracking('GetDummyAssetsUseCase.execute');
        return result;
      } else if (versionChange == VersionChange.none) {
        // For major version changes, use current implementation
        final result = _handleNoVersionChange(localManifest);
        PerformanceTracker.endTracking('GetDummyAssetsUseCase.execute');
        return result;
      } else {
        // For minor/patch changes, use local manifest and update in background
        final result = await _handleMinorPatchChange(localManifest);
        PerformanceTracker.endTracking('GetDummyAssetsUseCase.execute');
        return result;
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to execute GetDummyAssetsUseCase', e, stackTrace);
      PerformanceTracker.endTracking('GetDummyAssetsUseCase.execute');
      rethrow;
    }
  }

  /// Handle major version changes with immediate asset updates
  Future<T> _handleMajorVersionChange() async {
    PerformanceTracker.startTracking('_handleMajorVersionChange');

    // Use the repository to fetch remote data using the current version
    PerformanceTracker.startTracking('getRemoteManifest');
    final AssetManifest remoteManifest = await _repository.getRemoteManifest(
      _currentVersion,
    );
    PerformanceTracker.endTracking('getRemoteManifest');

    // Get local manifest for comparison
    PerformanceTracker.startTracking('getLocalManifest_majorChange');
    final AssetManifest? localManifest = await _repository.getLocalManifest();
    PerformanceTracker.endTracking('getLocalManifest_majorChange');

    // Analyze the differences between local and remote manifests
    PerformanceTracker.startTracking('compareManifests');
    final ManifestDifference diff =
        _manifestCompareUseCase.compareManifests(localManifest, remoteManifest);
    PerformanceTracker.endTracking('compareManifests');

    // P0 assets need to be processed immediately
    PerformanceTracker.startTracking('saveP0AssetsToLocalStorage');
    await _saveAssetsToLocalStorage(diff.priorityAssets.p0);
    PerformanceTracker.endTracking('saveP0AssetsToLocalStorage');

    // Generate the initial assets map with P0 assets
    PerformanceTracker.startTracking('generateDummyAssets_P0Only');
    await _generateDummyAssets(
      remoteManifest,
      0,
    );
    PerformanceTracker.endTracking('generateDummyAssets_P0Only');

    // _dummyAssets.value = dummyAssets;

    // Process remaining assets in the background
    _updateAssetsInBackground(diff, remoteManifest);

    PerformanceTracker.endTracking('_handleMajorVersionChange');
    return _dummyAssets!;
  }

  /// Handle minor or patch version changes using local manifest first
  Future<T> _handleMinorPatchChange(
    AssetManifest localManifest,
  ) async {
    PerformanceTracker.startTracking('_handleMinorPatchChange');

    // Generate assets using only local manifest
    PerformanceTracker.startTracking('generateDummyAssets_local');
    await _generateDummyAssets(
      localManifest,
      null,
    );
    PerformanceTracker.endTracking('generateDummyAssets_local');

    // Start remote manifest update in background
    _updateRemoteAssetsInBackground(localManifest);

    PerformanceTracker.endTracking('_handleMinorPatchChange');
    return _dummyAssets!;
  }

  /// Handle no version changes using local manifest first
  Future<T> _handleNoVersionChange(
    AssetManifest localManifest,
  ) async {
    PerformanceTracker.startTracking('_handleNoVersionChange');

    // Generate assets using only local manifest
    PerformanceTracker.startTracking('generateDummyAssets_local');
    await _generateDummyAssets(
      localManifest,
      null,
    );
    PerformanceTracker.endTracking('generateDummyAssets_local');

    PerformanceTracker.endTracking('_handleNoVersionChange');
    return _dummyAssets!;
  }

  /// Process remaining assets and update in background
  Future<void> _updateAssetsInBackground(
    ManifestDifference diff,
    AssetManifest remoteManifest,
  ) async {
    PerformanceTracker.startTracking('_updateAssetsInBackground');

    try {
      // Process lower priority assets in the background
      PerformanceTracker.startTracking('processBackgroundAssets');
      await _processBackgroundAssets(
        p1Assets: diff.priorityAssets.p1,
        p2Assets: diff.priorityAssets.p2,
        remoteManifest: remoteManifest,
      );
      PerformanceTracker.endTracking('processBackgroundAssets');

      // Clean up removed assets
      PerformanceTracker.startTracking('cleanupBasedOnDiff');
      await _deleteRemovedAssets(diff.removedAssets);

      PerformanceTracker.endTracking('cleanupBasedOnDiff');

      // Update the asset map with all priorities
      PerformanceTracker.startTracking('generateDummyAssets_allPriorities');
      await _generateDummyAssets(remoteManifest, null);
      PerformanceTracker.endTracking('generateDummyAssets_allPriorities');

      _logger.info('Background asset update complete');
    } catch (e, stackTrace) {
      _logger.error('Error in background asset update', e, stackTrace);
    }

    PerformanceTracker.endTracking('_updateAssetsInBackground');
  }

  /// Update assets from remote in background for minor/patch changes
  Future<void> _updateRemoteAssetsInBackground(
      AssetManifest localManifest) async {
    PerformanceTracker.startTracking('_updateRemoteAssetsInBackground');

    try {
      // Fetch remote manifest in background
      PerformanceTracker.startTracking('getRemoteManifest_background');
      final AssetManifest remoteManifest =
          await _repository.getRemoteManifest(_currentVersion);
      PerformanceTracker.endTracking('getRemoteManifest_background');

      // Compare manifests
      PerformanceTracker.startTracking('compareManifests_background');
      final ManifestDifference diff = _manifestCompareUseCase.compareManifests(
          localManifest, remoteManifest);
      PerformanceTracker.endTracking('compareManifests_background');

      // Process all assets in background
      PerformanceTracker.startTracking('processAllBackgroundAssets');
      await _processBackgroundAssets(
        p0Assets: diff.priorityAssets.p0,
        p1Assets: diff.priorityAssets.p1,
        p2Assets: diff.priorityAssets.p2,
        remoteManifest: remoteManifest,
      );
      PerformanceTracker.endTracking('processAllBackgroundAssets');

      // Clean up any removed assets
      PerformanceTracker.startTracking('cleanupBasedOnDiff_background');

      await _deleteRemovedAssets(diff.removedAssets);

      PerformanceTracker.endTracking('cleanupBasedOnDiff_background');

      _logger.info(
          'Background remote asset update complete for minor/patch change');
    } catch (e, stackTrace) {
      _logger.error('Error in background remote asset update', e, stackTrace);
    }

    PerformanceTracker.endTracking('_updateRemoteAssetsInBackground');
  }

  Future<void> _generateDummyAssets(
    AssetManifest manifest,
    int? priorityFilter,
  ) async {
    // Use the AssetUrlGenerator to create the asset map
    Map<String, String> assetMap = {};
    for (final asset in manifest.assets) {
      if (priorityFilter == null || asset.priority == priorityFilter) {
        assetMap[asset.path] = DynamicAssetUrl(
          path: asset.path,
          version: manifest.version,
        ).toUrl();
      }
    }

    _logger.info('Asset map generated with ${assetMap.length} assets');

    _logger.debug('Generated DummyAssets with ${assetMap.length} assets');
    _assetMapper.updateFromAssetMap(_dummyAssets!, assetMap);
  }

  /// Save assets to local storage
  Future<void> _saveAssetsToLocalStorage(List<AssetItem> assetList) async {
    if (assetList.isEmpty) return;

    _logger.info('Saving ${assetList.length} assets to local storage');

    // Process each asset in parallel for efficiency
    await Future.wait(
      assetList.map((asset) => _downloadAndSaveAsset(asset)),
    );
  }

  /// Download and save a single asset based on its type
  Future<void> _downloadAndSaveAsset(AssetItem asset) async {
    try {
      _logger.debug('Downloading image: ${asset.url}');

      final Uint8List imageBytes =
          await _repository.loadImageFromUrl(asset.url);

      // Delegate saving to the specialized use case
      final format = _getImageFormat(asset.path);
      final response = await _saveUint8Image(
        assetPath: asset.path,
        imageBytes: imageBytes,
        format: format,
      );

      _logger.debug(
        'Saved image: ${asset.path} (${response.imageBytesLength} bytes)',
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to process asset ${asset.path}', e, stackTrace);
    }
  }

  /// Determine image format from file extension
  String _getImageFormat(String path) {
    final String ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      case 'bmp':
        return 'bmp';
      default:
        return 'png'; // default format
    }
  }

  /// Process prioritized assets in background
  /// Downloads P1 and P2 assets and updates the manifest
  Future<void> _processBackgroundAssets({
    List<AssetItem> p0Assets = const [],
    required List<AssetItem> p1Assets,
    required List<AssetItem> p2Assets,
    required AssetManifest remoteManifest,
  }) async {
    try {
      // Process P0, P1 and P2 assets in order
      await _saveAssetsToLocalStorage(p0Assets);
      await _saveAssetsToLocalStorage(p1Assets);
      await _saveAssetsToLocalStorage(p2Assets);

      // Save the updated manifest to local storage
      await _repository.setLocalManifest(remoteManifest);

      _logger.info('Background asset processing complete');
    } catch (e, stackTrace) {
      _logger.error('Error in background asset processing', e, stackTrace);
    }
  }

  Future<ImageUploadResponse> _saveUint8Image({
    required String assetPath,
    required Uint8List imageBytes,
    String format = 'png',
  }) async {
    PerformanceTracker.startTracking('SaveUint8ListImageUseCase.execute');

    try {
      _logger.debug(
          'Saving image to path: $assetPath (${imageBytes.length} bytes)');

      final dataUri =
          _uint8ListToBase64String(imageBytes: imageBytes, format: format);

      // Save the image data to local storage
      await _repository.saveAssetByPath(assetPath, dataUri);

      _logger.debug(
          'Successfully saved image: $assetPath (${imageBytes.length} bytes)');

      return ImageUploadResponse(
        imageBytesLength: imageBytes.length,
        isSuccess: true,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to save image: $assetPath', e, stackTrace);
      return ImageUploadResponse(
        imageBytesLength: 0,
        isSuccess: false,
      );
    } finally {
      PerformanceTracker.endTracking('SaveUint8ListImageUseCase.execute');
    }
  }

  String _uint8ListToBase64String({
    required Uint8List imageBytes,
    String format = 'png',
  }) {
    final String base64Image = base64Encode(imageBytes);

    // Add data URI prefix for proper handling
    final String dataUri = 'data:image/$format;base64,$base64Image';

    return dataUri;
  }

  /// Delete assets that have been removed from the manifest
  Future<void> _deleteRemovedAssets(List<AssetItem> removedAssets) async {
    if (removedAssets.isEmpty) return;

    _logger.info('Deleting ${removedAssets.length} removed assets');

    // Delete each asset from storage
    for (var asset in removedAssets) {
      try {
        await _repository.deleteAssetByPath(asset.path);
        _logger.debug('Deleted asset: ${asset.path}');
      } catch (e) {
        _logger.error('Failed to delete asset ${asset.path}', e);
      }
    }
  }

  Future<void> deleteAllData() async {
    try {
      // Step 1: Get the local manifest first to know which assets to delete
      final manifest = await _repository.getLocalManifest();

      // Step 2: Delete all the assets if we have a manifest
      if (manifest != null) {
        for (var asset in manifest.assets) {
          await _repository.deleteAssetByPath(asset.path);
          print('Deleted asset: ${asset.path}');
        }
      }

      // Step 3: Clear the manifest from SharedPreferences
      await _repository.clearLocalManifest();

      print('All local assets and manifest cleared successfully');
    } catch (e) {
      print('Error clearing local assets: $e');
    }
  }
}
