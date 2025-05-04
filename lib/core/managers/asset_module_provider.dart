import 'package:flutter/foundation.dart';
import '../services/asset_service.dart';
import 'module_asset_manager.dart';

/// Provider for managing assets across different modules
class AssetModuleProvider extends ChangeNotifier {
  final AssetService _assetService;
  final Map<String, ModuleAssetManager> _moduleManagers = {};
  
  AssetModuleProvider({
    required AssetService assetService,
  }) : _assetService = assetService;
  
  /// Get a module manager for a specific module
  Future<ModuleAssetManager> getModuleManager(String moduleName) async {
    if (!_moduleManagers.containsKey(moduleName)) {
      final manager = ModuleAssetManager(
        assetService: _assetService,
        moduleName: moduleName,
      );
      
      _moduleManagers[moduleName] = manager;
      await manager.initialize();
    }
    
    return _moduleManagers[moduleName]!;
  }
  
  /// Check for updates across all modules
  Future<void> checkForUpdates() async {
    final futures = _moduleManagers.values.map((manager) => manager.checkForUpdates());
    await Future.wait(futures);
    notifyListeners();
  }
  
  /// Check if a module is ready
  bool isModuleReady(String moduleName) {
    if (!_moduleManagers.containsKey(moduleName)) {
      return false;
    }
    
    return _moduleManagers[moduleName]!.state == AssetUpdateState.ready;
  }
  
  /// Get image path for a module asset
  String? getAssetPath(String moduleName, String assetPath) {
    if (!isModuleReady(moduleName)) {
      return null;
    }
    
    final fullPath = '$moduleName/$assetPath';
    if (_assetService.assetExists(fullPath)) {
      return _assetService.getAssetPath(fullPath);
    }
    
    return null;
  }
  
  @override
  void dispose() {
    for (final manager in _moduleManagers.values) {
      manager.dispose();
    }
    super.dispose();
  }
}