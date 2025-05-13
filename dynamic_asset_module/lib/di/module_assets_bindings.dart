import 'package:dynamic_asset_module/data/sources/local_asset_data_source.dart';
import 'package:dynamic_asset_module/data/sources/remote_asset_data_source.dart';
import 'package:dynamic_asset_module/edge/asset_mapper.dart';
import 'package:dynamic_asset_module/usecases/get_dummy_assets_usecase.dart';
import 'package:dynamic_asset_module/usecases/manifest_compare_usecase.dart';
import 'package:dynamic_asset_module/usecases/version_compare_usecase.dart';

import 'package:dynamic_asset_module/data/dummy_data_repository.dart';
import 'package:dynamic_asset_module/usecases/ensure_zero_pixel_image_exists_usecase.dart';

class ModuleAssetsConfig {
  String currentAssetVersion;
  //TODO we need to remove this
  void setCurrentAssetVersion(String version) {
    currentAssetVersion = version;
  }

  ModuleAssetsConfig({
    required this.currentAssetVersion,
  });
}

/// Dependency provider for the module assets feature
class ModuleAssetsDependencyProvider<T> {
  final AssetMapper<T> _assetMapper;

  DummyDataRepository? _dummyDataRepository;

  // Use cases
  ManifestCompareUseCase? _manifestCompareUseCase;
  GetDummyAssetsUseCase? _getDummyAssetsUseCase;
  VersionCompareUseCase? _versionCompareUseCase;

  final ModuleAssetsConfig _assetsConfig;

  LocalAssetDataSource? _localDataSource;
  RemoteAssetDataSource? _remoteDataSource;

  // Constructor with platform info
  ModuleAssetsDependencyProvider({
    required ModuleAssetsConfig assetsConfig,
    required AssetMapper<T> assetMapper,
  })  : _assetMapper = assetMapper,
        _assetsConfig = assetsConfig;

  LocalAssetDataSource _provideLocalDataSource() {
    return _localDataSource ??= LocalAssetDataSource();
  }

  RemoteAssetDataSource _provideRemoteDataSource() {
    return _remoteDataSource ??= RemoteAssetDataSource();
  }

  // Provide dummy data repository
  DummyDataRepository provideDummyDataRepository() {
    return _dummyDataRepository ??= DummyDataRepository(
      localDataSource: _provideLocalDataSource(),
      remoteDataSource: _provideRemoteDataSource(),
    );
  }

  // Provide manifest compare use case
  ManifestCompareUseCase _provideManifestCompareUseCase() {
    return _manifestCompareUseCase ??= ManifestCompareUseCase();
  }

  // Provide version compare use case
  VersionCompareUseCase _provideVersionCompareUseCase() {
    return _versionCompareUseCase ??= VersionCompareUseCase(
      _assetsConfig.currentAssetVersion,
    );
  }

  // Provide get dummy assets use case
  GetDummyAssetsUseCase provideGetDummyAssetsUseCase() {
    _getDummyAssetsUseCase ??= GetDummyAssetsUseCase(
      repository: provideDummyDataRepository(),
      manifestCompareUseCase: _provideManifestCompareUseCase(),
      assetMapper: _assetMapper,
      versionCompareUseCase: _provideVersionCompareUseCase(),
      zeroPixelImageDataGenerator: ZeroPixelImageDataGeneratorUsecase(),
      currentVersion: _assetsConfig.currentAssetVersion,
    );
    return _getDummyAssetsUseCase!;
  }

  // Dispose all dependencies
  void disposeDependencies() {
    _dummyDataRepository = null;
    _manifestCompareUseCase = null;
    _getDummyAssetsUseCase = null;
    _versionCompareUseCase = null;
  }
}
