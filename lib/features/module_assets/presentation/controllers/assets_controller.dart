import 'package:get/get.dart';
import '../../domain/usecases/get_dummy_assets_usecase.dart';

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
  final GetDummyAssetsUseCase _getDummyAssetsUseCase;
  late final AssetsControllerUIState state;

  AssetsController({
    required GetDummyAssetsUseCase getDummyAssetsUseCase,
  })  : _getDummyAssetsUseCase = getDummyAssetsUseCase,
        state = AssetsControllerUIState(
            dummyAssets: DummyAssets(
          p0AssetList: [],
          p1AssetList: [],
          p2AssetList: [],
        ).obs) {
    // Initialize assets asynchronously
    _initAssets();
  }

  Future<void> _initAssets() async {
    state.dummyAssets = await _getDummyAssetsUseCase.execute();
  }
}

class AssetsControllerUIState {
  Rx<DummyAssets> dummyAssets;

  AssetsControllerUIState({required this.dummyAssets});
}
