import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/generate_dummy_assets_usecase.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/manifest_compare_usecase.dart';

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
}