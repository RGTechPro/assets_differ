import 'package:assets_differ/core/services/file_storage_service.dart';
import 'package:assets_differ/core/utils/performance_tracker.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all local storage operations for assets
class LocalAssetDataSource {
  // Key for storing manifest in SharedPreferences
  static const String _manifestKey = 'local_asset_manifest';

  /// Retrieves the locally stored asset manifest
  Future<AssetManifest?> getLocalManifest() async {
    try {
      // Get instance of SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Retrieve stored manifest JSON string
      final String? manifestJson = prefs.getString(_manifestKey);

      if (manifestJson != null && manifestJson.isNotEmpty) {
        // Parse the JSON string to AssetManifest
        return AssetManifest.fromJsonString(manifestJson);
      }
    } catch (e) {
      print('Error retrieving manifest from SharedPreferences: $e');
    }

    // Return null if no stored manifest is found or an error occurs
    return null;
  }

  /// Stores the asset manifest locally
  Future<void> setLocalManifest(AssetManifest manifest) async {
    try {
      // Convert manifest to JSON string
      final String manifestJson = manifest.toJsonString();

      // Store in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_manifestKey, manifestJson);

      print('Local manifest updated in SharedPreferences');
    } catch (e) {
      print('Error saving manifest to SharedPreferences: $e');
    }
  }

  /// Deletes an asset at the specified path
  Future<bool> deleteAssetByPath(String path) async {
    PerformanceTracker.startTracking('LocalAssetDataSource.deleteAssetByPath');
    try {
      final result = await FileStorageService.instance.deleteAssetByPath(path);
      if (result) {
        print('Asset deleted successfully: $path');
      } else {
        print('Asset not found or could not be deleted: $path');
      }
      return result;
    } catch (e) {
      print('Error deleting asset: $e');
      return false;
    } finally {
      PerformanceTracker.endTracking('LocalAssetDataSource.deleteAssetByPath');
    }
  }

  /// Retrieves an asset at the specified path
  Future<String> getAssetByPath(String path) async {
    PerformanceTracker.startTracking('LocalAssetDataSource.getAssetByPath');
    try {
      final data = await FileStorageService.instance.getAssetByPath(path);

      if (data.isNotEmpty) {
        return data;
      } else {
        print('Asset not found: $path');
        return '';
      }
    } catch (e) {
      print('Error retrieving asset: $e');
      return '';
    } finally {
      PerformanceTracker.endTracking('LocalAssetDataSource.getAssetByPath');
    }
  }

  /// Saves an asset at the specified path
  Future<void> saveAssetByPath(String path, String data) async {
    PerformanceTracker.startTracking('LocalAssetDataSource.saveAssetByPath');
    try {
      await FileStorageService.instance.saveAssetByPath(path, data);
      print('Asset saved successfully: $path');
      print('Data size: ${data.length} bytes');
    } catch (e) {
      print('Error saving asset: $e');
    } finally {
      PerformanceTracker.endTracking('LocalAssetDataSource.saveAssetByPath');
    }
  }

  /// Clears the manifest from local storage
  Future<void> clearManifest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_manifestKey);
      print('Manifest cleared from SharedPreferences');
    } catch (e) {
      print('Error clearing manifest: $e');
    }
  }

  /// Gets the base path for storing local assets
  Future<String> baseLocalAssetPath() async {
    if (kIsWeb) {
      // For web platform, use a placeholder path since we'll store data in IndexedDB
      return '';
    } else {
      // For mobile/desktop platforms, use the actual file system
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/';
    }
  }
}