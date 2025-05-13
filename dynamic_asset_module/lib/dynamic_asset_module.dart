library dynamic_asset_module;

import 'package:dynamic_asset_module/edge/asset_mapper.dart';

import 'package:dynamic_asset_module/di/module_assets_bindings.dart';

class DynamicAssetModule<T> {
  final ModuleAssetsDependencyProvider _moduleAssetsDependencyProvider;

  DynamicAssetModule({
    required ModuleAssetsConfig moduleAssetsConfig,
    required AssetMapper<T> assetMapper,
  }) : _moduleAssetsDependencyProvider = ModuleAssetsDependencyProvider<T>(
          assetsConfig: moduleAssetsConfig,
          assetMapper: assetMapper,
        );

  /// Provides the asset mapper

  Future<T> load() async {
    return await _moduleAssetsDependencyProvider
        .provideGetDummyAssetsUseCase()
        .execute();
  }

  T get asset {
    return _moduleAssetsDependencyProvider
        .provideGetDummyAssetsUseCase()
        .dummyAssets;
  }

  Future<void> deleteAllData() async {
    await _moduleAssetsDependencyProvider
        .provideDummyDataRepository()
        .deleteAllData();
  }

  void dispose() {
    _moduleAssetsDependencyProvider.disposeDependencies();
  }
}
