import 'package:assets_differ/features/module_assets/domain/usecases/version_compare_usecase.dart';

import '../data/dummy_data_repository.dart';
import '../domain/usecases/get_dummy_assets_usecase.dart';
import '../domain/usecases/manifest_compare_usecase.dart';
import '../domain/usecases/asset_download_usecase.dart';
import '../domain/usecases/asset_cleanup_usecase.dart';
import '../domain/usecases/generate_dummy_assets_usecase.dart';

class ModuleAssetsConfig {
  final String curentAssetVersion;

  ModuleAssetsConfig({
    required this.curentAssetVersion,
  });
}

/// Dependency provider for the module assets feature
class ModuleAssetsDependencyProvider {
  DummyDataRepository? _dummyDataRepository;

  // Use cases
  ManifestCompareUseCase? _manifestCompareUseCase;
  AssetDownloadUseCase? _assetDownloadUseCase;
  AssetCleanupUseCase? _assetCleanupUseCase;
  GenerateDummyAssetsUseCase? _generateDummyAssetsUseCase;
  GetDummyAssetsUseCase? _getDummyAssetsUseCase;

  final ModuleAssetsConfig _assetsConfig;

  VersionCompareUseCase? _versionCompareUseCase;

  // Constructor with platform info
  ModuleAssetsDependencyProvider({
    required ModuleAssetsConfig assetsConfig,
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
    return _assetDownloadUseCase ??=
        AssetDownloadUseCase(provideDummyDataRepository());
  }

  // Provide asset cleanup use case
  AssetCleanupUseCase provideAssetCleanupUseCase() {
    return _assetCleanupUseCase ??=
        AssetCleanupUseCase(provideDummyDataRepository());
  }

  // Provide generate dummy assets use case
  GenerateDummyAssetsUseCase provideGenerateDummyAssetsUseCase() {
    return _generateDummyAssetsUseCase ??=
        GenerateDummyAssetsUseCase(provideDummyDataRepository());
  }

  VersionCompareUseCase provideVersionCompareUseCase() {
    return _versionCompareUseCase ??= VersionCompareUseCase(
      _assetsConfig.curentAssetVersion,
    );
  }

  // Provide get dummy assets use case
  GetDummyAssetsUseCase provideGetDummyAssetsUseCase() {
    _getDummyAssetsUseCase ??= GetDummyAssetsUseCase(
      repository: provideDummyDataRepository(),
      manifestCompareUseCase: provideManifestCompareUseCase(),
      assetDownloadUseCase: provideAssetDownloadUseCase(),
      assetCleanupUseCase: provideAssetCleanupUseCase(),
      generateDummyAssetsUseCase: provideGenerateDummyAssetsUseCase(),
      versionCompareUseCase: provideVersionCompareUseCase(),
      currentVersion: _assetsConfig.curentAssetVersion,
    );
    return _getDummyAssetsUseCase!;
  }

  // Dispose all dependencies
  void disposeDependencies() {
    _dummyDataRepository = null;
    _manifestCompareUseCase = null;
    _assetDownloadUseCase = null;
    _assetCleanupUseCase = null;
    _generateDummyAssetsUseCase = null;
    _getDummyAssetsUseCase = null;
  }
}
