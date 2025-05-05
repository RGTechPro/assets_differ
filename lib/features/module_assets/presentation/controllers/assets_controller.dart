import 'package:get/get.dart';

class DummyAssets {
  final List<String> p0AssetList;
  final List<String> p1AssetList;
  final List<String> p2AssetList;

  DummyAssets({
    required this.p0AssetList,
    required this.p1AssetList,
    required this.p2AssetList,
  });
}

class AssetsController extends GetxController {
  final Rx<DummyAssets> dummyAssets = DummyAssets(
    p0AssetList: [
      'https://cdn.example.com/assets/v1.0.0/images/logo.png',
      'https://cdn.example.com/assets/v2.0.0/images/logo.png',
    ],
    p1AssetList: [
      'https://cdn.example.com/assets/v1.0.0/icons/menu/menu_icon.png',
      'https://cdn.example.com/assets/v2.0.0/icons/menu/menu_icon.png',
    ],
    p2AssetList: [
      'https://cdn.example.com/assets/v1.0.0/banners/home/banner1.jpg',
      'https://cdn.example.com/assets/v2.0.0/banners/home/banner1.jpg',
    ],
  ).obs;

  void updateAssets(DummyAssets newAssets) {
    dummyAssets.value = newAssets;
  }
}