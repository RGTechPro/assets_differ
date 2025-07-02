import 'dart:convert';
import 'dart:typed_data';

import 'package:dynamic_asset_module/core/dynamic_asset_url.dart';
import 'package:dynamic_asset_module/domain/usecases/version_compare_usecase.dart';

import 'package:dynamic_asset_module/data/dummy_data_repository.dart';
import 'package:dynamic_asset_module/data/models/asset_manifest.dart';
import 'package:dynamic_asset_module/edge/asset_mapper.dart';
import 'package:dynamic_asset_module/domain/usecases/ensure_zero_pixel_image_exists_usecase.dart';
import 'package:dynamic_asset_module/domain/usecases/manifest_compare_usecase.dart';

/// Coordinator UseCase to provide and manage DummyAssets
/// Delegates specific tasks to specialized usecases
class GetDummyAssetsUseCase<T> {
  final DataRepository _repository;
  final ManifestCompareUseCase _manifestCompareUseCase;
  final VersionCompareUseCase _versionCompareUseCase;
  final ZeroPixelImageDataGeneratorUsecase _zeroPixelImageDataGenerator;
  final String _currentVersion;

  final AssetMapper<T> _assetMapper;

  T get dummyAssets => _dummyAssets!;

  T? _dummyAssets;

  final zeroPixelPath = kZeroPixel.path;

  GetDummyAssetsUseCase({
    required DataRepository repository,
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
        return;
      }
    } catch (e) {}

    // First ensure that the zero pixel placeholder image exists
    final uint8List = await _zeroPixelImageDataGenerator.execute();

    await _saveUint8Image(
      assetPath: zeroPixelPath,
      imageBytes: uint8List,
    );
  }

  /// Execute the use case to get DummyAssets as an Observable
  Future<T> execute() async {
    if (_dummyAssets != null) {
      // If assets are already loaded, return them
      return _dummyAssets!;
    }

    _dummyAssets = _assetMapper.empty();

    await _generateZeroPixelImage();

    try {
      final AssetManifest? localManifest = await _repository.getLocalManifest();

      if (localManifest == null) {
        // If no local manifest exists, we need to get everything from remote
        final result = await _handleMajorVersionChange();
        return result;
      }

      final VersionChange versionChange =
          _versionCompareUseCase.compareVersions(
        localManifest.version,
      );

      if (versionChange == VersionChange.major) {
        // For major version changes, use current implementation
        final result = await _handleMajorVersionChange();
        return result;
      } else if (versionChange == VersionChange.none) {
        // For major version changes, use current implementation
        final result = _handleNoVersionChange(localManifest);
        return result;
      } else {
        // For minor/patch changes, use local manifest and update in background
        final result = await _handleMinorPatchChange(localManifest);
        return result;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Handle major version changes with immediate asset updates
  Future<T> _handleMajorVersionChange() async {
    final AssetManifest remoteManifest = await _repository.getRemoteManifest(
      _currentVersion,
    );
    final AssetManifest? localManifest = await _repository.getLocalManifest();

    final ManifestDifference diff = _manifestCompareUseCase.compareManifests(
      localManifest,
      remoteManifest,
    );

    await _saveAssetsToLocalStorage(diff.priorityAssets.p0);

    await _generateDummyAssets(
      remoteManifest,
      0,
    );

    // Process remaining assets in the background
    _updateAssetsInBackground(diff, remoteManifest);

    return _dummyAssets!;
  }

  /// Handle minor or patch version changes using local manifest first
  Future<T> _handleMinorPatchChange(
    AssetManifest localManifest,
  ) async {
    await _generateDummyAssets(
      localManifest,
      null,
    );

    // Start remote manifest update in background
    _updateRemoteAssetsInBackground(localManifest);

    return _dummyAssets!;
  }

  /// Handle no version changes using local manifest first
  Future<T> _handleNoVersionChange(
    AssetManifest localManifest,
  ) async {
    await _generateDummyAssets(
      localManifest,
      null,
    );

    return _dummyAssets!;
  }

  /// Process remaining assets and update in background
  Future<void> _updateAssetsInBackground(
    ManifestDifference diff,
    AssetManifest remoteManifest,
  ) async {
    try {
      await _processBackgroundAssets(
        p1Assets: diff.priorityAssets.p1,
        p2Assets: diff.priorityAssets.p2,
        remoteManifest: remoteManifest,
      );

      await _deleteRemovedAssets(diff.removedAssets);

      await _generateDummyAssets(remoteManifest, null);
    } catch (e) {}
  }

  /// Update assets from remote in background for minor/patch changes
  Future<void> _updateRemoteAssetsInBackground(
    AssetManifest localManifest,
  ) async {
    try {
      final AssetManifest remoteManifest = await _repository.getRemoteManifest(
        _currentVersion,
      );

      final ManifestDifference diff = _manifestCompareUseCase.compareManifests(
        localManifest,
        remoteManifest,
      );

      await _processBackgroundAssets(
        p0Assets: diff.priorityAssets.p0,
        p1Assets: diff.priorityAssets.p1,
        p2Assets: diff.priorityAssets.p2,
        remoteManifest: remoteManifest,
      );

      await _deleteRemovedAssets(diff.removedAssets);
    } catch (e) {}
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
    _assetMapper.updateFromAssetMap(_dummyAssets as T, assetMap);
  }

  /// Save assets to local storage
  Future<void> _saveAssetsToLocalStorage(List<AssetItem> assetList) async {
    if (assetList.isEmpty) return;

    // Process each asset in parallel for efficiency
    await Future.wait(
      assetList.map((asset) => _downloadAndSaveAsset(asset)),
    );
  }

  /// Download and save a single asset based on its type
  Future<void> _downloadAndSaveAsset(AssetItem asset) async {
    try {
      final Uint8List imageBytes =
          await _repository.loadImageFromUrl(asset.url);

      // Delegate saving to the specialized use case
      final format = _getImageFormat(asset.path);
      final response = await _saveUint8Image(
        assetPath: asset.path,
        imageBytes: imageBytes,
        format: format,
      );
    } catch (e) {}
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
    } catch (e) {}
  }

  Future<ImageUploadResponse> _saveUint8Image({
    required String assetPath,
    required Uint8List imageBytes,
    String format = 'png',
  }) async {
    try {
      final dataUri =
          _uint8ListToBase64String(imageBytes: imageBytes, format: format);

      // Save the image data to local storage
      await _repository.saveAssetByPath(assetPath, dataUri);

      return ImageUploadResponse(
        imageBytesLength: imageBytes.length,
        isSuccess: true,
      );
    } catch (e) {
      return ImageUploadResponse(
        imageBytesLength: 0,
        isSuccess: false,
      );
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

    // Delete each asset from storage
    for (var asset in removedAssets) {
      try {
        await _repository.deleteAssetByPath(asset.path);
      } catch (e) {}
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
