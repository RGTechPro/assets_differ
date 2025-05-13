import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';
import 'package:assets_differ/features/module_assets/presentation/model/dummy_asset.dart';
import 'package:dynamic_asset_module/dynamic_asset_module.dart';
import 'package:flutter/material.dart';
import 'package:assets_differ/features/module_assets/presentation/home_screen.dart';

/// Routes configuration for the app
class AppRoutes {
  // Route names
  static const String home = '/';
  static const String splash = '/splash';
  static const String assets = '/assets';

  /// Generate routes for the app
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case splash:
        if (args is DynamicAssetModule<DummyAssets>) {
          return MaterialPageRoute(
            builder: (_) => SplashScreen(dependencyProvider: args),
          );
        }
        return _errorRoute('ModuleAssetsDependencyProvider required');

      case assets:
        if (args is DynamicAssetModule<DummyAssets>) {
          return MaterialPageRoute(
            builder: (_) => P0AssetsScreen(dependencyProvider: args),
          );
        }
        return _errorRoute('ModuleAssetsDependencyProvider required');

      default:
        return _errorRoute('Route not found');
    }
  }

  /// Generate an error route
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(
            'Navigation Error: $message',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}