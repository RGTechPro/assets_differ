import 'package:assets_differ/core/config/asset_config.dart';
import 'package:assets_differ/core/managers/asset_module_provider.dart';
import 'package:assets_differ/core/services/asset_service.dart';
import 'package:assets_differ/features/module_assets/data/asset_repository.dart';
import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:assets_differ/features/module_assets/data/repository/repository_interface.dart';
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
                onPressed: () {
                  // Initialize bindings for proper dependency injection
                  final bindings = ModuleAssetsBindings();
                  bindings.dependencies();

                  // Now we can safely find the controller with all dependencies injected
                  final assetsController = Get.find<AssetsController>();

                  Get.to(() => NewScreen());
                },
                child: const Text("Demo")),
            ElevatedButton(
              onPressed: () async {
                // Show confirmation dialog
                final bool? confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Assets'),
                    content: const Text(
                        'This will delete all downloaded assets and reset the app. Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                // If user confirmed, clear all assets
                if (confirmDelete == true) {
                  // Show loading indicator
                  final scaffold = ScaffoldMessenger.of(context);

                  // Initialize bindings for dependency injection
                  final bindings = ModuleAssetsBindings();
                  bindings.dependencies();

                  // Get the repository
                  final repository = Get.find<DummyDataRepository>();

                  // Clear all assets
                  await repository.clearAllLocalAssets();

                  // Show success message
                  scaffold.showSnackBar(
                    const SnackBar(
                      content: Text('All assets cleared successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Rebuild the screen
                  setState(() {
                    _initializeAssetProvider();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Clear All Assets"),
            ),
          ],
        ),
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
    // assetsController.onInit();
  }

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
  // Get the repository for loading assets
  final BaseAssetRepository repository = Get.find<BaseAssetRepository>();

  Future<String> _loadAssetContent(String assetPath) async {
    try {
      // Get the asset content using the repository
      final data = await repository.getAssetByPath(assetPath);
      return data;
    } catch (e) {
      print('Error loading asset: $e');
      return '';
    }
  }

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
              final assetPath = assetsController.state.p0Section!.asset.value;

              return FutureBuilder<String>(
                future: _loadAssetContent(assetPath),
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
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 60),
                          const SizedBox(height: 20),
                          Text('Error loading asset: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  final assetContent = snapshot.data ?? '';
                  return ImageCard(
                    asset: assetContent,
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
            if ((assetsController.state.p1Section?.asset.isEmpty ?? true) ||
                (assetsController.state.p2Section?.asset.isEmpty ?? true)) {
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
  // Get the repository for loading assets
  final BaseAssetRepository repository = Get.find<BaseAssetRepository>();

  Future<String> _loadAssetContent(String assetPath) async {
    try {
      // Get the asset content using the repository
      final data = await repository.getAssetByPath(assetPath);
      return data;
    } catch (e) {
      print('Error loading asset: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P1 Assets - Important'),
      ),
      body: Obx(
        () {
          if (assetsController.state.p1Section?.asset.isEmpty ?? true) {
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

          final assetPath = assetsController.state.p1Section!.asset.value;

          return FutureBuilder<String>(
            future: _loadAssetContent(assetPath),
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
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 60),
                      const SizedBox(height: 20),
                      Text('Error loading asset: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final assetContent = snapshot.data ?? '';
              return ImageCard(
                asset: assetContent,
                title: assetsController.state.p1Section!.title,
              );
            },
          );
        },
      ),
    );
  }
}

/// Screen displaying P2 assets
class P2AssetsScreen extends StatelessWidget {
  P2AssetsScreen({Key? key}) : super(key: key);

  // Get the controller
  final AssetsController assetsController = Get.find<AssetsController>();
  // Get the repository for loading assets
  final BaseAssetRepository repository = Get.find<BaseAssetRepository>();

  Future<String> _loadAssetContent(String assetPath) async {
    try {
      // Get the asset content using the repository
      final data = await repository.getAssetByPath(assetPath);
      return data;
    } catch (e) {
      print('Error loading asset: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2 Assets - Optional'),
      ),
      body: Obx(() {
        if (assetsController.state.p2Section?.asset.isEmpty ?? true) {
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

        final assetPath = assetsController.state.p2Section!.asset.value;

        return FutureBuilder<String>(
          future: _loadAssetContent(assetPath),
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
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 60),
                    const SizedBox(height: 20),
                    Text('Error loading asset: ${snapshot.error}'),
                  ],
                ),
              );
            }

            final assetContent = snapshot.data ?? '';
            return ImageCard(
              asset: assetContent,
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
