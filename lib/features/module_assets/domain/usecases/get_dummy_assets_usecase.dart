import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:get/get.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/manifest_compare_usecase.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/asset_download_usecase.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/asset_cleanup_usecase.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/generate_dummy_assets_usecase.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/version_compare_usecase.dart';

/// Coordinator UseCase to provide and manage DummyAssets
/// Delegates specific tasks to specialized usecases
class GetDummyAssetsUseCase {
  final DummyDataRepository _repository;
  final ManifestCompareUseCase _manifestCompareUseCase;
  final AssetDownloadUseCase _assetDownloadUseCase;
  final AssetCleanupUseCase _assetCleanupUseCase;
  final GenerateDummyAssetsUseCase _generateDummyAssetsUseCase;
  final VersionCompareUseCase _versionCompareUseCase;
  final String _currentVersion;
  final _logger = AssetLogger('GetDummyAssetsUseCase');

  // Observable asset state
  final Rx<DummyAssets> _dummyAssets = DummyAssets(
    logoImage: kZeroPixel,
    menuIcon: kZeroPixel,
    bannerImage: kZeroPixel,
  ).obs;

  GetDummyAssetsUseCase({
    required DummyDataRepository repository,
    required ManifestCompareUseCase manifestCompareUseCase,
    required AssetDownloadUseCase assetDownloadUseCase,
    required AssetCleanupUseCase assetCleanupUseCase,
    required GenerateDummyAssetsUseCase generateDummyAssetsUseCase,
    required VersionCompareUseCase versionCompareUseCase,
   required String currentVersion, 
  })  : _currentVersion = currentVersion, _repository = repository,
        _manifestCompareUseCase = manifestCompareUseCase,
        _assetDownloadUseCase = assetDownloadUseCase,
        _assetCleanupUseCase = assetCleanupUseCase,
        _generateDummyAssetsUseCase = generateDummyAssetsUseCase,
        _versionCompareUseCase = versionCompareUseCase;

  /// The current DummyAssets as an observable
  Rx<DummyAssets> get dummyAssets => _dummyAssets;

  /// Execute the use case to get DummyAssets as an Observable
  Future<DummyAssets> execute() async {
    try {
      // First, load local manifest to get the current version
      final AssetManifest? localManifest = await _repository.getLocalManifest();

      if (localManifest == null) {
        // If no local manifest exists, we need to get everything from remote
        return _handleMajorVersionChange();
      }

      // Check version differences using the dedicated usecase
      final VersionChange versionChange =
          _versionCompareUseCase.compareVersions(
        localManifest.version,
      );

      if (versionChange == VersionChange.major) {
        // For major version changes, use current implementation
        return _handleMajorVersionChange();
      } else {
        // For minor/patch changes, use local manifest and update in background
        return _handleMinorPatchChange(localManifest);
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to execute GetDummyAssetsUseCase', e, stackTrace);
      rethrow;
    }
  }

  /// Handle major version changes with immediate asset updates
  Future<DummyAssets> _handleMajorVersionChange() async {
    // Use the repository to fetch remote data using the current version
    final AssetManifest remoteManifest = await _repository.getRemoteManifest(
     _currentVersion,
    );

    // Get local manifest for comparison
    final AssetManifest? localManifest = await _repository.getLocalManifest();

    // Analyze the differences between local and remote manifests
    final ManifestDifference diff =
        _manifestCompareUseCase.compareManifests(localManifest, remoteManifest);

    // P0 assets need to be processed immediately
    await _assetDownloadUseCase
        .saveAssetsToLocalStorage(diff.priorityAssets.p0);

    // Generate the initial assets map with P0 assets
    final dummyAssets = await _generateDummyAssetsUseCase.generateDummyAssets(
      remoteManifest,
      0,
    );
    _dummyAssets.value = dummyAssets;

    // Process remaining assets in the background
    _updateAssetsInBackground(diff, remoteManifest);

    return dummyAssets;
  }

  /// Handle minor or patch version changes using local manifest first
  Future<DummyAssets> _handleMinorPatchChange(
    AssetManifest localManifest,
  ) async {
    // Generate assets using only local manifest
    final dummyAssets = await _generateDummyAssetsUseCase.generateDummyAssets(
      localManifest,
      null,
    );
    _dummyAssets.value = dummyAssets;

    // Start remote manifest update in background
    _updateRemoteAssetsInBackground(localManifest);

    return dummyAssets;
  }

  /// Process remaining assets and update in background
  Future<void> _updateAssetsInBackground(
    ManifestDifference diff,
    AssetManifest remoteManifest,
  ) async {
    try {
      // Process lower priority assets in the background
      await _assetDownloadUseCase.processBackgroundAssets(
        p1Assets: diff.priorityAssets.p1,
        p2Assets: diff.priorityAssets.p2,
        remoteManifest: remoteManifest,
      );

      // Clean up removed assets
      await _assetCleanupUseCase.cleanupBasedOnDiff(diff);

      // Update the asset map with all priorities
      final dummyAssets = await _generateDummyAssetsUseCase.generateDummyAssets(
          remoteManifest, null);
      _dummyAssets.value = dummyAssets;

      _logger.info('Background asset update complete');
    } catch (e, stackTrace) {
      _logger.error('Error in background asset update', e, stackTrace);
    }
  }

  /// Update assets from remote in background for minor/patch changes
  Future<void> _updateRemoteAssetsInBackground(
      AssetManifest localManifest) async {
    try {
      // Fetch remote manifest in background
      final AssetManifest remoteManifest =
          await _repository.getRemoteManifest(_currentVersion);

      // Compare manifests
      final ManifestDifference diff = _manifestCompareUseCase.compareManifests(
          localManifest, remoteManifest);

      // Process all assets in background
      await _assetDownloadUseCase.processBackgroundAssets(
        p0Assets: diff.priorityAssets.p0,
        p1Assets: diff.priorityAssets.p1,
        p2Assets: diff.priorityAssets.p2,
        remoteManifest: remoteManifest,
      );

      // Clean up any removed assets
      await _assetCleanupUseCase.cleanupBasedOnDiff(diff);

      // Update asset map if needed
      if (diff.hasChanges) {
        final dummyAssets = await _generateDummyAssetsUseCase
            .generateDummyAssets(remoteManifest, null);
        _dummyAssets.value = dummyAssets;
      }

      _logger.info(
          'Background remote asset update complete for minor/patch change');
    } catch (e, stackTrace) {
      _logger.error('Error in background remote asset update', e, stackTrace);
    }
  }
}
