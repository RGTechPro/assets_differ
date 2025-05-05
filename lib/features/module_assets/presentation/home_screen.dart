import 'package:assets_differ/core/config/asset_config.dart';
import 'package:assets_differ/core/managers/asset_module_provider.dart';
import 'package:assets_differ/core/services/asset_service.dart';
import 'package:assets_differ/features/module_assets/data/asset_repository.dart';
import 'package:assets_differ/features/module_assets/di/module_assets_bindings.dart';
import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'module_assets_screen.dart';

/// Home screen that lists available modules
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<AssetModuleProvider> _providerFuture;

  @override
  void initState() {
    super.initState();
    _initializeAssetProvider();
  }

  Future<void> _initializeAssetProvider() async {
    _providerFuture = AssetService.getInstance(
      baseApiUrl: AssetConfig.baseApiUrl,
      appVersion: AssetConfig.appVersion,
      brandId: AssetConfig.defaultBrandId,
    ).then((assetService) {
      return AssetModuleProvider(assetService: assetService);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Differ Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializeAssetProvider();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<AssetModuleProvider>(
        future: _providerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Error initializing asset service',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeAssetProvider();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final provider = snapshot.data!;
          return _buildModuleList(provider);
        },
      ),
    );
  }

  Widget _buildModuleList(AssetModuleProvider provider) {
    
    return Column(
      children: [
        ElevatedButton(
            onPressed: () {
                // // Initialize bindings for proper dependency injection
                // Get.put(provider.assetService);
                // Get.lazyPut(() => AssetRepository(Get.find<AssetService>()));
                
                // Use ModuleAssetsBindings to properly inject dependencies
                final bindings = ModuleAssetsBindings();
                bindings.dependencies();
                
                // Now we can safely find the controller with all dependencies injected
                final assetsController = Get.find<AssetsController>();

                Get.to(() => NewScreen());
            },
            child: const Text("demo")),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: AssetConfig.modules.length,
            itemBuilder: (context, index) {
              final moduleName = AssetConfig.modules[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    moduleName.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                      'Contains ${AssetConfig.demoAssets[moduleName]?.length ?? 0} assets'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final moduleManager =
                        await provider.getModuleManager(moduleName);
                    if (!mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModuleAssetsScreen(
                          moduleName: moduleName,
                          moduleManager: moduleManager,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


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

class NewScreen extends StatelessWidget {
  NewScreen({Key? key}) : super(key: key);

  // Get the controller
  final AssetsController assetsController = Get.find<AssetsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Demo'),
      ),
      body: Obx(() {
        final dummyAssets = assetsController.dummyAssets.value;
        return Column(
          children: [
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.horizontal,
                itemCount: dummyAssets.p0AssetList.length,
                itemBuilder: (context, index) {
                  final asset = dummyAssets.p0AssetList[index];
                  return CommonImage(asset: asset, priority: 0);
                },
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.horizontal,
                itemCount: dummyAssets.p1AssetList.length,
                itemBuilder: (context, index) {
                  final asset = dummyAssets.p1AssetList[index];
                  return CommonImage(asset: asset, priority: 1);
                },
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.horizontal,
                itemCount: dummyAssets.p2AssetList.length,
                itemBuilder: (context, index) {
                  final asset = dummyAssets.p2AssetList[index];
                  return CommonImage(asset: asset, priority: 2);
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class CommonImage extends StatelessWidget {
  const CommonImage({
    super.key,
    required this.asset,
    required this.priority,
  });

  final String asset;
  final int priority;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority: $priority',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Center(
              child: Image.network(
                asset,
                height: 150,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
