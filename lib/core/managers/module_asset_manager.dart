import 'dart:async';
import '../services/asset_service.dart';
import '../models/asset_models.dart';
import '../../features/module_assets/data/asset_repository.dart';

/// Manager for handling module assets
class ModuleAssetManager {
  final AssetService _assetService;
  final String _moduleName;
  late final AssetRepository _repository;
  
  /// Stream controller for asset update events
  final StreamController<AssetUpdateEvent> _updateEventController = 
      StreamController<AssetUpdateEvent>.broadcast();
  
  /// Stream of asset update events
  Stream<AssetUpdateEvent> get updateEvents => _updateEventController.stream;
  
  /// Current state of module assets
  AssetUpdateState _state = AssetUpdateState.notInitialized;
  AssetUpdateState get state => _state;
  
  ModuleAssetManager({
    required AssetService assetService,
    required String moduleName,
  })  : _assetService = assetService,
        _moduleName = moduleName {
    _repository = AssetRepository(_assetService);
  }
  
  /// Initialize and check for updates
  Future<void> initialize() async {
    _updateState(AssetUpdateState.initializing);
    
    try {
      final String? currentVersion = await _assetService.getModuleVersion(_moduleName);
      
      if (currentVersion == null) {
        _updateState(AssetUpdateState.needsUpdate);
      } else {
        _updateState(AssetUpdateState.ready);
      }
    } catch (e) {
      _updateState(AssetUpdateState.error);
      _updateEventController.add(AssetUpdateEvent(
        state: AssetUpdateState.error,
        error: e.toString(),
      ));
    }
  }
  
  /// Check for and apply asset updates
  Future<bool> checkForUpdates() async {
    _updateState(AssetUpdateState.updating);
    
    try {
      // Using our simulated repository instead of the actual API
      final success = await _repository.simulateUpdateCheck(_moduleName);
      
      if (success) {
        _updateState(AssetUpdateState.ready);
        _updateEventController.add(AssetUpdateEvent(
          state: AssetUpdateState.ready,
          version: "1.0.0", // Simulated version
        ));
        return true;
      } else {
        _updateState(AssetUpdateState.error);
        _updateEventController.add(AssetUpdateEvent(
          state: AssetUpdateState.error,
          error: "Failed to update assets",
        ));
        return false;
      }
    } catch (e) {
      _updateState(AssetUpdateState.error);
      _updateEventController.add(AssetUpdateEvent(
        state: AssetUpdateState.error,
        error: e.toString(),
      ));
      return false;
    }
  }
  
  /// Update the state and notify listeners
  void _updateState(AssetUpdateState newState) {
    _state = newState;
    _updateEventController.add(AssetUpdateEvent(state: newState));
  }
  
  /// Dispose resources
  void dispose() {
    _updateEventController.close();
  }
}

/// States for asset updates
enum AssetUpdateState {
  notInitialized,
  initializing,
  needsUpdate,
  updating,
  ready,
  error,
}

/// Event for asset updates
class AssetUpdateEvent {
  final AssetUpdateState state;
  final String? version;
  final String? error;
  
  AssetUpdateEvent({
    required this.state,
    this.version,
    this.error,
  });
}