import 'dart:async';

import 'package:assets_differ/features/module_assets/presentation/home_screen.dart';
import 'package:get/get.dart';
import '../../domain/usecases/get_dummy_assets_usecase.dart';

class DummyAssets {
    final String logoImage;
    final String menuIcon;
    final String bannerImage;
    DummyAssets({required this.logoImage, required this.menuIcon, required this.bannerImage});
  }
class AssetsController extends GetxController {
  final GetDummyAssetsUseCase _getDummyAssetsUseCase;
  late final AssetsControllerUIState state;
  final DummyAssets _dummyAssets ;
  AssetsController({
    required GetDummyAssetsUseCase getDummyAssetsUseCase,
  })  : _getDummyAssetsUseCase = getDummyAssetsUseCase,
        state = AssetsControllerUIState(
          p0Section: AssetsSectionUIState(
            title: 'P0 Assets',
            assetList: RxList<String>(),
          ),
          p1Section: AssetsSectionUIState(
            title: 'P1 Assets',
            assetList: RxList<String>(),
          ),
          p2Section: AssetsSectionUIState(
            title: 'P2 Assets',
            assetList: RxList<String>(),
          ),
        );

  StreamSubscription? _assetsSubscription;

  Future<void> _initAssets() async {
    // Fetch dummy assets and update the UI state
    _getDummyAssetsUseCase.execute();
  _getDummyAssetsUseCase.isP0Completed.then((_) {
      // Navigate to P0 assets screen once P0 is loaded
      Get.off(() => P0AssetsScreen());
    });
    // _getDummyAssetsUseCase.isP1P2Completed.then((_) {
    //   state.p0Section?.assetList.refresh();
    //   state.p1Section?.assetList.refresh();
    //   state.p2Section?.assetList.refresh();
    // });

    // state.p0Section?.assetList.value = _dummyAssets.sectionOneAssetList;
    // state.p1Section?.assetList.value = _dummyAssets.sectionTwoAssetList;
    // state.p2Section?.assetList.value = _dummyAssets.sectionThreeAssetList;
  }

  @override
  void onInit() {
    _initAssets();
    super.onInit();
  }

  @override
  void onClose() {
    _assetsSubscription?.cancel();
    super.onClose();
  }
}

class AssetsControllerUIState {
  AssetsSectionUIState? p0Section;
  AssetsSectionUIState? p1Section;
  AssetsSectionUIState? p2Section;

  AssetsControllerUIState({
    required this.p0Section,
    required this.p1Section,
    required this.p2Section,
  });
}

class AssetsSectionUIState {
  final String title;
  final RxList<String> assetList;

  AssetsSectionUIState({
    required this.title,
    required this.assetList,
  });
}
