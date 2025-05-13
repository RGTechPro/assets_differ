import 'package:dynamic_asset_module/edge/asset_mapper.dart';
import 'package:get/get.dart';

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

class DummyAssetsMapper extends AssetMapper<DummyAssets> {
  @override
  DummyAssets empty() {
    return DummyAssets(
      logoImage: RxString(defaultAssetPath),
      menuIcon: RxString(defaultAssetPath),
      bannerImage: RxString(defaultAssetPath),
    );
  }

  @override
  void updateFromAssetMap(DummyAssets assets, Map<String, String> json) {
    assets.logoImage.value = json['assets/logo.png'] ?? defaultAssetPath;
    assets.menuIcon.value = json['assets/menu_icon.png'] ?? defaultAssetPath;
    assets.bannerImage.value = json['assets/banner1.png'] ?? defaultAssetPath;
  }
}