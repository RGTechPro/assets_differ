import 'dart:async';
import 'package:assets_differ/features/module_assets/presentation/home_screen.dart';
import 'package:get/get.dart';
import '../../domain/usecases/get_dummy_assets_usecase.dart';

const String kZeroPixel = 'assets/images/zero_pixel.png';

class DummyAssets {
    final String logoImage;
    final String menuIcon;
    final String bannerImage;
    DummyAssets({required this.logoImage, required this.menuIcon, required this.bannerImage});

    factory DummyAssets.fromAssetMap(Map<String, String> json) {
      return DummyAssets(
        logoImage: json['assets/logo.png'] ?? kZeroPixel,
        menuIcon: json['assets/menu_icon.png'] ?? kZeroPixel,
        bannerImage: json['assets/banner.png'] ?? kZeroPixel,
      );
    }
  }
class AssetsController extends GetxController {
  final GetDummyAssetsUseCase _getDummyAssetsUseCase;
  late final AssetsControllerUIState state;
  AssetsController({
    required GetDummyAssetsUseCase getDummyAssetsUseCase,
  })  : _getDummyAssetsUseCase = getDummyAssetsUseCase,
        state = AssetsControllerUIState(
          p0Section: AssetsSectionUIState(
            title: 'P0 Assets',
            asset: kZeroPixel.obs,
          ),
          p1Section: AssetsSectionUIState(
            title: 'P1 Assets',
            asset:kZeroPixel.obs,
          ),
          p2Section: AssetsSectionUIState(
            title: 'P2 Assets',
            asset: kZeroPixel.obs,
          ),
        ){    _initAssets();
}

  StreamSubscription? _assetsSubscription;

  Future<void> _initAssets() async {
    // Fetch dummy assets and update the UI state
    _getDummyAssetsUseCase.execute().then((value) => Get.off(() => P0AssetsScreen()));
    
  _assetsSubscription = _getDummyAssetsUseCase.dummyAssets.listen((data) {
      state.p0Section?.asset.value = data.logoImage;
      state.p1Section?.asset.value = data.menuIcon;
      state.p2Section?.asset.value = data.bannerImage;
    });
  }

  @override
  void onInit() {
    // _initAssets();
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
  final RxString asset;

  AssetsSectionUIState({
    required this.title,
    required this.asset,
  });
}
