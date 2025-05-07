import '../data/dummy_data_repository.dart';
import '../domain/usecases/get_dummy_assets_usecase.dart';
import '../domain/usecases/manifest_compare_usecase.dart';
import '../domain/usecases/asset_download_usecase.dart';
import '../domain/usecases/asset_cleanup_usecase.dart';
import '../domain/usecases/generate_dummy_assets_usecase.dart';

/// Dependency provider for the module assets feature
class ModuleAssetsDependencyProvider {

  DummyDataRepository? _dummyDataRepository;
  // BaseAssetRepository? _baseAssetRepository;

  // Use cases
  ManifestCompareUseCase? _manifestCompareUseCase;
  AssetDownloadUseCase? _assetDownloadUseCase;
  AssetCleanupUseCase? _assetCleanupUseCase;
  GenerateDummyAssetsUseCase? _generateDummyAssetsUseCase;
  GetDummyAssetsUseCase? _getDummyAssetsUseCase;

  // Platform info
  final PlatformInfo _platformInfo;

  // Constructor with platform info
  ModuleAssetsDependencyProvider({
    required PlatformInfo platformInfo,
  }) : _platformInfo = platformInfo;

  // Provide dummy data repository
  DummyDataRepository provideDummyDataRepository() {
    _dummyDataRepository ??= DummyDataRepository();
    return _dummyDataRepository!;
  }

  // // Provide base asset repository
  // BaseAssetRepository provideBaseAssetRepository() {
  //   _baseAssetRepository ??= provideDummyDataRepository();
  //   return _baseAssetRepository!;
  // }

  // Provide manifest compare use case
  ManifestCompareUseCase provideManifestCompareUseCase() {
    _manifestCompareUseCase ??= ManifestCompareUseCase();
    return _manifestCompareUseCase!;
  }

  // Provide asset download use case
  AssetDownloadUseCase provideAssetDownloadUseCase() {
    _assetDownloadUseCase ??= AssetDownloadUseCase(provideDummyDataRepository());
    return _assetDownloadUseCase!;
  }

  // Provide asset cleanup use case
  AssetCleanupUseCase provideAssetCleanupUseCase() {
    _assetCleanupUseCase ??= AssetCleanupUseCase(provideDummyDataRepository());
    return _assetCleanupUseCase!;
  }

  // Provide generate dummy assets use case
  GenerateDummyAssetsUseCase provideGenerateDummyAssetsUseCase() {
    _generateDummyAssetsUseCase ??= GenerateDummyAssetsUseCase(provideDummyDataRepository());
    return _generateDummyAssetsUseCase!;
  }

  // Provide get dummy assets use case
  GetDummyAssetsUseCase provideGetDummyAssetsUseCase() {
    _getDummyAssetsUseCase ??= GetDummyAssetsUseCase(
          repository: provideDummyDataRepository(),
      platformInfo: _platformInfo,
      manifestCompareUseCase: provideManifestCompareUseCase(),
      assetDownloadUseCase: provideAssetDownloadUseCase(),
      assetCleanupUseCase: provideAssetCleanupUseCase(),
      generateDummyAssetsUseCase: provideGenerateDummyAssetsUseCase(),
    );
    return _getDummyAssetsUseCase!;
  }

  // Dispose all dependencies
  void disposeDependencies() {
    _dummyDataRepository = null;
    // _baseAssetRepository = null;
    _manifestCompareUseCase = null;
    _assetDownloadUseCase = null;
    _assetCleanupUseCase = null;
    _generateDummyAssetsUseCase = null;
    _getDummyAssetsUseCase = null;
  }
}
