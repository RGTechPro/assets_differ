import 'package:assets_differ/core/config/asset_config.dart';
import 'package:assets_differ/core/managers/asset_module_provider.dart';
import 'package:assets_differ/core/services/asset_service.dart';
import 'package:assets_differ/features/module_assets/data/asset_repository.dart';
import 'package:assets_differ/features/module_assets/di/module_assets_bindings.dart';
import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io';
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

/// Splash screen that starts loading assets and navigates to main screen when P0 assets are loaded
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late AssetsController assetsController;

  @override
  void initState() {
  assetsController = Get.find<AssetsController>();

    super.initState();
assetsController.onInit();  }

  // Future<void> _initAssetsAndNavigate() async {
  //   // Initialize bindings for proper dependency injection
  //   final bindings = ModuleAssetsBindings();
  //   bindings.dependencies();

  //   // Get the controller with all dependencies injected
  //   assetsController = Get.find<AssetsController>();
    
  //   // Start loading assets (non-awaited as requested)
  //   assetsController._getDummyAssetsUseCase.execute();
    
  //   // Wait only for P0 assets to complete before navigating
  //   assetsController._getDummyAssetsUseCase.isP0Completed.then((_) {
  //     // Navigate to P0 assets screen once P0 is loaded
  //     Get.off(() => P0AssetsScreen());
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your splash logo or animation here
            const FlutterLogo(size: 100),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Loading Priority Assets...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main screen displaying P0 assets with navigation to P1 and P2 screens
class P0AssetsScreen extends StatelessWidget {
  P0AssetsScreen({Key? key}) : super(key: key);

  // Get the controller
  final AssetsController assetsController = Get.find<AssetsController>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P0 Assets - Critical'),
      ),
      body: Column(
        children: [
          // P0 Assets section
          Expanded(
            child: Obx(() {
              // if (assetsController.state.p0Section?.assetList.isEmpty ?? true) {
              //   return const Center(
              //     child: Text('No P0 assets available'),
              //   );
              // }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 1,
                itemBuilder: (context, index) {
                  final asset = "images/logo.png"; // Placeholder for actual asset
                  return ImageCard(
                    asset: asset,
                    title: assetsController.state.p0Section!.title,
                  );
                },
              );
            }),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Get.to(() => P1AssetsScreen());
                  },
                  child: const Text('View P1 Assets'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.to(() => P2AssetsScreen());
                  },
                  child: const Text('View P2 Assets'),
                ),
              ],
            ),
          ),
          
          // Loading indicator for P1 and P2 assets
          Obx(() {
            // Show loading indicator for P1/P2 assets if they're not yet loaded
            if ((assetsController.state.p1Section?.assetList.isEmpty ?? true) ||
                (assetsController.state.p2Section?.assetList.isEmpty ?? true)) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(height: 8),
                    Text('Loading additional assets...'),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}

/// Screen displaying P1 assets
class P1AssetsScreen extends StatelessWidget {
  P1AssetsScreen({Key? key}) : super(key: key);

  // Get the controller
  final AssetsController assetsController = Get.find<AssetsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P1 Assets - Important'),
      ),
      body: Obx(() {
        if (assetsController.state.p1Section?.assetList.isEmpty ?? true) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Loading P1 assets...'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assetsController.state.p1Section!.assetList.length,
          itemBuilder: (context, index) {
            final asset = assetsController.state.p1Section!.assetList[index];
            return ImageCard(
              asset: asset,
              title: assetsController.state.p1Section!.title,
            );
          },
        );
      }),
    );
  }
}

/// Screen displaying P2 assets
class P2AssetsScreen extends StatelessWidget {
  P2AssetsScreen({Key? key}) : super(key: key);

  // Get the controller
  final AssetsController assetsController = Get.find<AssetsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2 Assets - Optional'),
      ),
      body: Obx(() {
        if (assetsController.state.p2Section?.assetList.isEmpty ?? true) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Loading P2 assets...'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assetsController.state.p2Section!.assetList.length,
          itemBuilder: (context, index) {
            final asset = assetsController.state.p2Section!.assetList[index];
            return ImageCard(
              asset: asset,
              title: assetsController.state.p2Section!.title,
            );
          },
        );
      }),
    );
  }
}

/// Widget to display images with support for base64, URL sources, and file paths
class ImageCard extends StatelessWidget {
  const ImageCard({
    Key? key,
    required this.asset,
    required this.title,
  }) : super(key: key);

  final String asset;
  final String title;

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
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Center(
              child: _buildImage(asset),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImage(String source) {
    // Check if the source is a file path (starts with / on macOS/Linux or contains :\ for Windows)
    if (source.startsWith('/') || source.contains(':\\')) {
      // Load from file
      return Image.file(
        File(source),
        height: 150,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 150);
        },
      );
    }
    // Check if the source is base64 encoded
    else if (source.startsWith('data:image') || 
        RegExp(r'^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$')
            .hasMatch(source)) {
      try {
        // Extract base64 data if it's a data URI
        String base64String = source;
        if (source.contains(',')) {
          base64String = source.split(',')[1];
        }
        
        // Decode base64 to bytes
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          height: 150,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 150);
          },
        );
      } catch (e) {
        return const Icon(Icons.broken_image, size: 150);
      }
    } else {
      // Treat as network URL
      return Image.network(
        source,
        height: 150,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 150);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }
  }
}

// Replace the original NewScreen with SplashScreen as entry point
class NewScreen extends StatelessWidget {
  NewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
