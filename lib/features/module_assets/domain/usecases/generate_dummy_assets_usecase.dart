import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';

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
      assetMap[asset.path] = await _repository.getAssetRefPath(asset.path);
    }

    _logger.debug('Generated DummyAssets with ${assetMap.length} assets');
    return DummyAssets.fromAssetMap(assetMap);
  }
}

/// Simple logger class for asset operations
class AssetLogger {
  final String _tag;

  AssetLogger(this._tag);

  void debug(String message) {
    if (kDebugMode) print('[$_tag] DEBUG: $message');
  }

  void info(String message) {
    print('[$_tag] INFO: $message');
  }

  void warn(String message) {
    print('[$_tag] WARN: $message');
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    print('[$_tag] ERROR: $message${error != null ? ' - $error' : ''}');
    if (kDebugMode && stackTrace != null) {
      print('[$_tag] STACK: $stackTrace');
    }
  }
}