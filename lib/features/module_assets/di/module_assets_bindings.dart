import 'package:assets_differ/features/module_assets/domain/usecases/ensure_zero_pixel_image_exists_usecase.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/version_compare_usecase.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/save_uint8list_image_usecase.dart';
import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';

import '../data/dummy_data_repository.dart';
import '../domain/usecases/get_dummy_assets_usecase.dart';
import '../domain/usecases/manifest_compare_usecase.dart';
import '../domain/usecases/asset_download_usecase.dart';
import '../domain/usecases/asset_cleanup_usecase.dart';

class ModuleAssetsConfig {
  final String curentAssetVersion;

  ModuleAssetsConfig({
    required this.curentAssetVersion,
  });
}

/// Dependency provider for the module assets feature
class ModuleAssetsDependencyProvider<T> {
  final AssetMapper<T> assetMapper;

  DummyDataRepository? _dummyDataRepository;

  // Use cases
  ManifestCompareUseCase? _manifestCompareUseCase;
  AssetDownloadUseCase? _assetDownloadUseCase;
  AssetCleanupUseCase? _assetCleanupUseCase;
  GetDummyAssetsUseCase? _getDummyAssetsUseCase;
  VersionCompareUseCase? _versionCompareUseCase;
  SaveUint8ListImageUseCase? _saveUint8ListImageUseCase;

  final ModuleAssetsConfig _assetsConfig;

  // Constructor with platform info
  ModuleAssetsDependencyProvider({
    required ModuleAssetsConfig assetsConfig,
    required this.assetMapper,
  }) : _assetsConfig = assetsConfig;

  // Provide dummy data repository
  DummyDataRepository provideDummyDataRepository() {
    return _dummyDataRepository ??= DummyDataRepository();
  }

  // Provide manifest compare use case
  ManifestCompareUseCase provideManifestCompareUseCase() {
    return _manifestCompareUseCase ??= ManifestCompareUseCase();
  }

  // Provide asset download use case
  AssetDownloadUseCase provideAssetDownloadUseCase() {
    return _assetDownloadUseCase ??= AssetDownloadUseCase(
      saveUint8ListImageUseCase: provideSaveUint8ListImageUseCase(),
      repository: provideDummyDataRepository(),
    );
  }

  // Provide asset cleanup use case
  AssetCleanupUseCase provideAssetCleanupUseCase() {
    return _assetCleanupUseCase ??=
        AssetCleanupUseCase(provideDummyDataRepository());
  }


  // Provide version compare use case
  VersionCompareUseCase provideVersionCompareUseCase() {
    return _versionCompareUseCase ??= VersionCompareUseCase(
      _assetsConfig.curentAssetVersion,
    );
  }

  // Provide get dummy assets use case
  GetDummyAssetsUseCase provideGetDummyAssetsUseCase() {
    _getDummyAssetsUseCase ??= GetDummyAssetsUseCase(
      repository: provideDummyDataRepository(),
      saveUint8ListImageUseCase: provideSaveUint8ListImageUseCase(),
      manifestCompareUseCase: provideManifestCompareUseCase(),
      assetDownloadUseCase: provideAssetDownloadUseCase(),
      assetCleanupUseCase: provideAssetCleanupUseCase(),
      assetMapper: assetMapper,
      versionCompareUseCase: provideVersionCompareUseCase(),
      zeroPixelImageDataGenerator: ZeroPixelImageDataGeneratorUsecase(),
      currentVersion: _assetsConfig.curentAssetVersion,
    );
    return _getDummyAssetsUseCase!;
  }

  // Provide save Uint8List image use case
  SaveUint8ListImageUseCase provideSaveUint8ListImageUseCase() {
    return _saveUint8ListImageUseCase ??=
        SaveUint8ListImageUseCase(provideDummyDataRepository());
  }

  // Dispose all dependencies
  void disposeDependencies() {
    _dummyDataRepository = null;
    _manifestCompareUseCase = null;
    _assetDownloadUseCase = null;
    _assetCleanupUseCase = null;
    _getDummyAssetsUseCase = null;
    _versionCompareUseCase = null;
    _saveUint8ListImageUseCase = null;
  }
}
