import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/manifest_compare_usecase.dart';

import 'package:assets_differ/core/logging.dart';

/// UseCase for cleaning up and deleting assets
class AssetCleanupUseCase {
  final DummyDataRepository _repository;
  final _logger = AssetLogger('AssetCleanupUseCase');

  AssetCleanupUseCase(this._repository);

  /// Delete assets that have been removed from the manifest
  Future<void> deleteRemovedAssets(List<AssetItem> removedAssets) async {
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

  /// Clean up all local assets based on a difference report
  Future<void> cleanupBasedOnDiff(ManifestDifference diff) async {
    if (diff.removedAssets.isEmpty) return;

    await deleteRemovedAssets(diff.removedAssets);
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
