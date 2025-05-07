import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';
import 'package:assets_differ/features/module_assets/domain/repository/repository_interface.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/manifest_compare_usecase.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/asset_download_usecase.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/asset_cleanup_usecase.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/generate_dummy_assets_usecase.dart';

/// Coordinator UseCase to provide and manage DummyAssets
/// Delegates specific tasks to specialized usecases
class GetDummyAssetsUseCase {
  final PlatformInfo _platformInfo;
  final BaseAssetRepository _repository;
  final ManifestCompareUseCase _manifestCompareUseCase;
  final AssetDownloadUseCase _assetDownloadUseCase;
  final AssetCleanupUseCase _assetCleanupUseCase;
  final GenerateDummyAssetsUseCase _generateDummyAssetsUseCase;
  final _logger = AssetLogger('GetDummyAssetsUseCase');

  // Observable asset state
  final Rx<DummyAssets> _dummyAssets = DummyAssets(
    logoImage: kZeroPixel,
    menuIcon: kZeroPixel,
    bannerImage: kZeroPixel,
  ).obs;

  GetDummyAssetsUseCase({
    required BaseAssetRepository repository,
    required PlatformInfo platformInfo,
    required ManifestCompareUseCase manifestCompareUseCase,
    required AssetDownloadUseCase assetDownloadUseCase,
    required AssetCleanupUseCase assetCleanupUseCase,
    required GenerateDummyAssetsUseCase generateDummyAssetsUseCase,
  })  : _repository = repository,
        _platformInfo = platformInfo,
        _manifestCompareUseCase = manifestCompareUseCase,
        _assetDownloadUseCase = assetDownloadUseCase,
        _assetCleanupUseCase = assetCleanupUseCase,
        _generateDummyAssetsUseCase = generateDummyAssetsUseCase;

  /// The current DummyAssets as an observable
  Rx<DummyAssets> get dummyAssets => _dummyAssets;

  /// Execute the use case to get DummyAssets as an Observable
  Future<DummyAssets> execute() async {
    try {
      // First, load local manifest to get the current version
      final AssetManifest? localManifest = await _repository.getLocalManifest();

      // Use the repository to fetch remote data using the current version
      final AssetManifest remoteManifest =
          await _repository.getRemoteManifest(_platformInfo.version);

      // Analyze the differences between local and remote manifests
      final ManifestDifference diff =
          _manifestCompareUseCase.compareManifests(localManifest, remoteManifest);

      // P0 assets need to be processed immediately
      await _assetDownloadUseCase.saveAssetsToLocalStorage(diff.priorityAssets.p0);

      // Generate the initial assets map with P0 assets
      final dummyAssets = await _generateDummyAssetsUseCase.generateDummyAssets(
          remoteManifest, 0);
      _dummyAssets.value = dummyAssets;

      // Process remaining assets in the background
      _updateAssetsInBackground(diff, remoteManifest);

      return dummyAssets;
    } catch (e, stackTrace) {
      _logger.error('Failed to execute GetDummyAssetsUseCase', e, stackTrace);
      rethrow;
    }
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
}

class PlatformInfo {
  final String version;

  PlatformInfo({
    required this.version,
  });
}
