import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';

import 'package:assets_differ/core/logging.dart';

/// UseCase for generating DummyAssets objects from asset manifests
class GenerateDummyAssetsUseCase {
  final DummyDataRepository _repository;
  final _logger = AssetLogger('GenerateDummyAssetsUseCase');

  GenerateDummyAssetsUseCase(this._repository);

  /// Generate a DummyAssets object from assets in the manifest
  /// If priorityFilter is provided, only includes assets with that priority
  Future<DummyAssets> generateDummyAssets(
    AssetManifest manifest,
    int? priorityFilter,
  ) async {

    Map<String, String> assetMap = {};

    // Filter assets by priority if needed
    final assetsToInclude = priorityFilter != null
        ? manifest.assets.where((e) => e.priority == priorityFilter)
        : manifest.assets;

    // Build the asset map
    for (var asset in assetsToInclude) {
      assetMap[asset.path] = "${await _repository.getAssetRefPath(asset.path)};${manifest.version}";
    }

    _logger.debug('Generated DummyAssets with ${assetMap.length} assets');
    return DummyAssets.fromAssetMap(assetMap);
  }
}