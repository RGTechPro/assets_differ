import 'package:flutter/foundation.dart';
import 'package:assets_differ/core/utils/performance_tracker.dart';
import 'storage_implementation.dart';
import 'storage_interface.dart';

/// Service for managing file-based asset storage with web support
class FileStorageService {
  static FileStorageService? _instance;
  late final StorageInterface _storage;
  
  /// Private constructor
  FileStorageService._() {
    _storage = getStorageImplementation();
  }
  
  /// Singleton instance
  static FileStorageService get instance {
    _instance ??= FileStorageService._();
    return _instance!;
  }
  
  /// Save asset data by path
  Future<void> saveAssetByPath(String assetPath, String data) async {
    PerformanceTracker.startTracking('FileStorageService.saveAssetByPath');
    try {
      print('Attempting to save asset with path: $assetPath');
      
      PerformanceTracker.startTracking('FileStorageService._storage.saveAsset');
      await _storage.saveAsset(assetPath, data);
      PerformanceTracker.endTracking('FileStorageService._storage.saveAsset');
      
      print('Asset saved: $assetPath (${data.length} bytes)');
    } catch (e) {
      print('Error saving asset: $e');
    } finally {
      PerformanceTracker.endTracking('FileStorageService.saveAssetByPath');
    }
  }
  
  /// Get asset data by path
  Future<String> getAssetByPath(String assetPath) async {
    PerformanceTracker.startTracking('FileStorageService.getAssetByPath');
    try {
      print('Attempting to retrieve asset with path: $assetPath');
      
      PerformanceTracker.startTracking('FileStorageService._storage.getAsset');
      final data = await _storage.getAsset(assetPath);
      PerformanceTracker.endTracking('FileStorageService._storage.getAsset');
      
      if (data.isNotEmpty) {
        print('Retrieved asset: $assetPath (${data.length} bytes)');
      } else {
        print('Asset not found: $assetPath');
      }
      return data;
    } catch (e) {
      print('Error retrieving asset: $e');
      return '';
    } finally {
      PerformanceTracker.endTracking('FileStorageService.getAssetByPath');
    }
  }
  
  /// Delete asset by path
  Future<bool> deleteAssetByPath(String assetPath) async {
    PerformanceTracker.startTracking('FileStorageService.deleteAssetByPath');
    try {
      print('Attempting to delete asset with path: $assetPath');
      
      PerformanceTracker.startTracking('FileStorageService._storage.deleteAsset');
      final result = await _storage.deleteAsset(assetPath);
      PerformanceTracker.endTracking('FileStorageService._storage.deleteAsset');
      
      if (result) {
        print('Asset deleted successfully: $assetPath');
      } else {
        print('Asset not found for deletion: $assetPath');
      }
      return result;
    } catch (e) {
      print('Error deleting asset: $e');
      return false;
    } finally {
      PerformanceTracker.endTracking('FileStorageService.deleteAssetByPath');
    }
  }
  
  /// Close any open resources
  Future<void> closeResources() async {
    await _storage.close();
  }

}