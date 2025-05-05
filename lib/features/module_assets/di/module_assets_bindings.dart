import 'package:get/get.dart';
import '../data/asset_repository.dart';
import '../data/dummy_data_repository.dart';
import '../domain/usecases/get_dummy_assets_usecase.dart';
import '../presentation/controllers/assets_controller.dart';
import '../../../core/services/asset_service.dart';
import '../data/repository/repository_interface.dart';

/// Bindings for the module assets feature
class ModuleAssetsBindings extends Bindings {
  @override
  void dependencies() {
    // Register the regular repository
    Get.lazyPut<AssetRepository>(() => AssetRepository(
      Get.find<AssetService>()
    ));
    
    // Register the dummy repository
    Get.lazyPut<DummyDataRepository>(() => DummyDataRepository());
    
    // Register the DummyDataRepository as the implementation for BaseAssetRepository
    Get.lazyPut<BaseAssetRepository>(() => Get.find<DummyDataRepository>());

    // Register the use case with DummyDataRepository
    Get.lazyPut<GetDummyAssetsUseCase>(() => GetDummyAssetsUseCase(
      Get.find<BaseAssetRepository>()
    ));

    // Register the controller with the use case injected
    Get.lazyPut<AssetsController>(() => AssetsController(
      getDummyAssetsUseCase: Get.find<GetDummyAssetsUseCase>(),
    ));
  }
}