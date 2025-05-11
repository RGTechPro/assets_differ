import 'package:assets_differ/features/module_assets/di/module_assets_bindings.dart';
import 'package:get/get.dart';

const String kZeroPixel = 'assets/zero_pixel.png';

class DummyAssets {
  final RxString logoImage;
  final RxString menuIcon;
  final RxString bannerImage;

  DummyAssets({
    required this.logoImage,
    required this.menuIcon,
    required this.bannerImage,
  });
}

abstract class AssetMapper<T> {
  void updateFromAssetMap(T assets, Map<String, String> json);
  T empty();
}

class DummyAssetsMapper implements AssetMapper<DummyAssets> {
  const DummyAssetsMapper();
  @override
  DummyAssets empty() {
    return DummyAssets(
      logoImage: RxString(kZeroPixel),
      menuIcon: RxString(kZeroPixel),
      bannerImage: RxString(kZeroPixel),
    );
  }

  @override
  void updateFromAssetMap(DummyAssets assets, Map<String, String> json) {
    assets.logoImage.value = json['assets/logo.png'] ?? kZeroPixel;
    assets.menuIcon.value = json['assets/menu_icon.png'] ?? kZeroPixel;
    assets.bannerImage.value = json['assets/banner1.png'] ?? kZeroPixel;
  }
}

class AssetsController extends GetxController {
  late final AssetsControllerUIState state;
  AssetsController({
    required ModuleAssetsDependencyProvider dependencyProvider,
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
