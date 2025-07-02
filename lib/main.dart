import 'package:assets_differ/features/module_assets/presentation/model/dummy_asset.dart';
import 'package:dynamic_asset_module/di/module_assets_bindings.dart';
import 'package:dynamic_asset_module/dynamic_asset_module.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/config/app_routes.dart';

void main() {
  runApp(const AssetDifferApp());
}

class AssetDifferApp extends StatefulWidget {
  const AssetDifferApp({super.key});

  @override
  State<AssetDifferApp> createState() => _AssetDifferAppState();
}

class _AssetDifferAppState extends State<AssetDifferApp> {
  late final DynamicAssetModule<DummyAssets> dynamicAssetModule;

  late final AppRoutes appRoutes;

  @override
  void initState() {
    super.initState();
    dynamicAssetModule = DynamicAssetModule(
      assetMapper: DummyAssetsMapper(),
      moduleAssetsConfig: ModuleAssetsConfig(
        //TODO: set version from shared preferences
        currentAssetVersion: "1.0.0",
      ),
    );

    appRoutes = AppRoutes(
      dynamicAssetModule: dynamicAssetModule,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Asset Differ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.home,
      onGenerateRoute: appRoutes.onGenerateRoute,
    );
  }
}
