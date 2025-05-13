import 'package:assets_differ/features/module_assets/domain/usecases/ensure_zero_pixel_image_exists_usecase.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/version_compare_usecase.dart';
import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';

import '../data/dummy_data_repository.dart';
import '../domain/usecases/get_dummy_assets_usecase.dart';
import '../domain/usecases/manifest_compare_usecase.dart';

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

  // Constructor with platform info
  ModuleAssetsDependencyProvider({
    required ModuleAssetsConfig assetsConfig,
    required AssetMapper<T> assetMapper,
  }) : _assetMapper = assetMapper, _assetsConfig = assetsConfig;

  // Provide dummy data repository
  DummyDataRepository provideDummyDataRepository() {
    return _dummyDataRepository ??= DummyDataRepository();
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
