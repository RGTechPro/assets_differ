import 'dart:async';

import 'package:get/get.dart';
import '../../domain/usecases/get_dummy_assets_usecase.dart';

class DummyAssets {
  final List<String> sectionOneAssetList;
  final List<String> sectionTwoAssetList;
  final List<String> sectionThreeAssetList;

  DummyAssets({
    required this.sectionOneAssetList,
    required this.sectionTwoAssetList,
    required this.sectionThreeAssetList,
  });
}

class AssetsController extends GetxController {
  final GetDummyAssetsUseCase _getDummyAssetsUseCase;
  late final AssetsControllerUIState state;
  final DummyAssets _dummyAssets = DummyAssets(
    sectionOneAssetList: [],
    sectionTwoAssetList: [],
    sectionThreeAssetList: [],
  );

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

    _getDummyAssetsUseCase.isP1P2Completed.then((_) {
      state.p0Section?.assetList.refresh();
      state.p1Section?.assetList.refresh();
      state.p2Section?.assetList.refresh();
    });

    state.p0Section?.assetList.value = _dummyAssets.sectionOneAssetList;
    state.p1Section?.assetList.value = _dummyAssets.sectionTwoAssetList;
    state.p2Section?.assetList.value = _dummyAssets.sectionThreeAssetList;
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
