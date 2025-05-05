import 'package:flutter/foundation.dart';
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
    try {
      await _storage.saveAsset(assetPath, data);
      print('Asset saved: $assetPath');
    } catch (e) {
      print('Error saving asset: $e');
    }
  }
  
  /// Get asset data by path
  Future<String> getAssetByPath(String assetPath) async {
    try {
      final data = await _storage.getAsset(assetPath);
      return data;
    } catch (e) {
      print('Error retrieving asset: $e');
      return '';
    }
  }
  
  /// Delete asset by path
  Future<bool> deleteAssetByPath(String assetPath) async {
    try {
      final result = await _storage.deleteAsset(assetPath);
      return result;
    } catch (e) {
      print('Error deleting asset: $e');
      return false;
    }
  }
  
  /// Close any open resources
  Future<void> closeResources() async {
    await _storage.close();
  }
}