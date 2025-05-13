

import 'package:assets_differ/features/module_assets/presentation/model/dummy_asset.dart';
import 'package:get/get.dart';

class AssetsController extends GetxController {
  final AssetsControllerUIState state;
  AssetsController({
    required DummyAssets dummyAssets,
  }) : state = AssetsControllerUIState(
          p0Section: AssetsSectionUIState(
            title: 'P0 Assets',
            asset: dummyAssets.logoImage,
          ),
          p1Section: AssetsSectionUIState(
            title: 'P1 Assets',
            asset: dummyAssets.menuIcon,
          ),
          p2Section: AssetsSectionUIState(
            title: 'P2 Assets',
            asset: dummyAssets.bannerImage,
          ),
        );
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
  final RxString asset;

  AssetsSectionUIState({
    required this.title,
    required this.asset,
  });
}
