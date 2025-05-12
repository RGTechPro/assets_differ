import 'package:assets_differ/core/config/asset_config.dart';
import 'package:assets_differ/core/config/app_routes.dart';
import 'package:assets_differ/core/utils/performance_tracker.dart';
import 'package:assets_differ/core/widgets/image_providers.dart';
import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:assets_differ/features/module_assets/di/module_assets_bindings.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/asset_cleanup_usecase.dart';
import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';
import 'package:assets_differ/features/module_assets/presentation/widgets/version_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';

/// State class for the HomeScreenController
class HomeScreenState {
  final List<String> availableVersions = ['1.0.0', '1.1.0', '1.2.0'];
  final RxString selectedVersion;

  HomeScreenState({
    required this.selectedVersion,
  });
}

/// Controller for the home screen
class HomeScreenViewModel extends GetxController {
  final HomeScreenState state = HomeScreenState(
    selectedVersion: AssetConfig.appVersion.obs,
  );

  void onVersionChanged(String newVersion) {
    if (state.availableVersions.contains(newVersion)) {
      state.selectedVersion.value = newVersion;
    }
  }

  Future<void> clearAllAssets() async {
    try {
      AssetCleanupUseCase assetCleanupUseCase =
          AssetCleanupUseCase(DummyDataRepository());

      await assetCleanupUseCase.deleteAllData();

      Get.snackbar(
        'Success',
        'All assets cleared successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to clear assets: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

/// Home screen that lists available modules
class HomeScreen extends GetView<HomeScreenViewModel> {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Make sure the controller is initialized
    Get.put(HomeScreenViewModel());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Differ Demo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: VersionSelector(
              onVersionChanged: controller.onVersionChanged,
              selectedVersion: controller.state.selectedVersion,
              versions: controller.state.availableVersions,
            ),
          ),
          Expanded(
            child: _buildModuleList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleList(BuildContext context) {
    return Column(
      children: [
        // Display version info
        Container(
          padding: const EdgeInsets.all(12.0),
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Obx(
            () => Text(
              'Selected App Version: ${controller.state.selectedVersion.value}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
                onPressed: () {
                  // Create dependency provider with current selected version when navigating
                  final dependencyProvider = ModuleAssetsDependencyProvider(
                    assetMapper: const DummyAssetsMapper(),
                    assetsConfig: ModuleAssetsConfig(
                      curentAssetVersion:
                          controller.state.selectedVersion.value,
                    ),
                  );

                  // Use named route navigation
                  Navigator.pushNamed(
                    context,
                    AppRoutes.splash,
                    arguments: dependencyProvider,
                  );
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
                  controller.clearAllAssets();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Clear All Assets"),
            ),
          ],
        ),
      ],
    );
  }
}

/// Splash screen that starts loading assets and navigates to main screen when P0 assets are loaded
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    Key? key,
    required this.dependencyProvider,
  }) : super(key: key);

  final ModuleAssetsDependencyProvider dependencyProvider;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Start tracking the total time from splash screen to P0 assets screen
    PerformanceTracker.startTracking('SplashToP0Screen_TotalTime');
    
    _loadAssetsAndNavigate();
  }
  
  Future<void> _loadAssetsAndNavigate() async {
    try {
      // Start tracking the GetDummyAssetsUseCase execution initiated from splash screen
      PerformanceTracker.startTracking('SplashScreen_ExecuteUseCase');
      
      // Execute the use case with performance tracking
      widget.dependencyProvider.provideGetDummyAssetsUseCase().execute().then(
        (value) {
          PerformanceTracker.endTracking('SplashScreen_ExecuteUseCase');
          
          // Log a summary of the performance after the use case completes
          PerformanceTracker.logSummary();
          
          // Start tracking navigation time
          PerformanceTracker.startTracking('Navigate_ToP0Screen');
          
          // Use your preferred navigation approach
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.assets,
            arguments: widget.dependencyProvider,
          );
        },
      );
    } catch (e) {
      print('Error loading assets: $e');
      // Show error UI if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your splash logo or animation here
            FlutterLogo(size: 100),
            SizedBox(height: 30),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Loading Priority Assets...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main screen displaying all assets (P0, P1, and P2) in a single view
class P0AssetsScreen extends StatefulWidget {
  final AssetsController assetsController;
  final DummyDataRepository repository;

  P0AssetsScreen({
    Key? key,
    required ModuleAssetsDependencyProvider dependencyProvider,
  })  : assetsController = AssetsController(
          dependencyProvider: dependencyProvider,
          dummyAssets: dependencyProvider.provideGetDummyAssetsUseCase().dummyAssets,
        ),
        repository = dependencyProvider.provideDummyDataRepository(),
        super(key: key);

  @override
  State<P0AssetsScreen> createState() => _P0AssetsScreenState();
}

class _P0AssetsScreenState extends State<P0AssetsScreen> {
  @override
  void initState() {
    super.initState();
    widget.assetsController.onInit();
  }

  @override
  void dispose() {
    widget.assetsController.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority Assets Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // P0 Section - Critical Assets
          const Text(
            'P0 Critical Assets',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final assetPath =
                widget.assetsController.state.p0Section!.asset.value;
            return ImageCard(
              asset: assetPath,
              title: widget.assetsController.state.p0Section!.title,
            );
          }),

          const Divider(height: 32, thickness: 2),

          // P1 Section - Important Assets
          const Text(
            'P1 Important Assets',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Obx(
            () {
              if (widget.assetsController.state.p1Section?.asset.isEmpty ??
                  true) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text('Loading P1 assets...'),
                      ],
                    ),
                  ),
                );
              }

              final assetPath =
                  widget.assetsController.state.p1Section!.asset.value;

              return ImageCard(
                asset: assetPath,
                title: widget.assetsController.state.p1Section!.title,
              );
            },
          ),

          const Divider(height: 32, thickness: 2),

          // P2 Section - Optional Assets
          const Text(
            'P2 Optional Assets',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Obx(
            () {
              if (widget.assetsController.state.p2Section?.asset.isEmpty ??
                  true) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text('Loading P2 assets...'),
                      ],
                    ),
                  ),
                );
              }

              final assetPath =
                  widget.assetsController.state.p2Section!.asset.value;

              return ImageCard(
                asset: assetPath,
                title: widget.assetsController.state.p2Section!.title,
              );
            },
          ),
        ],
      ),
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
    return Image(
      image: FileAssetImageProvider(source),
      height: 150,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return SizedBox(
          height: 150,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 150,
          color: Colors.grey.shade200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 60, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ),
          ),
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // Add fade-in animation when image loads
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }
}
