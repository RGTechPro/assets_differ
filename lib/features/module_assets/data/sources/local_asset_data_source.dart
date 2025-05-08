import 'dart:convert';
import 'dart:io';

import 'package:assets_differ/core/services/file_storage_service.dart';
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
    }
  }

  /// Retrieves an asset at the specified path
  Future<Uint8List> getAssetByPath(String path) async {
    try {
      final data = await FileStorageService.instance.getAssetByPath(path);

      if (data.isNotEmpty) {
      
                  // Extract base64 data if it's a data URI
          String base64String = data;
          if (data.contains(',')) {
            base64String = data.split(',')[1];
          } // Decode base64 to bytes
            return base64Decode(base64String);
      } else {
        throw Exception('Asset not found: $path');
      }
    } catch (e) {
      return Uint8List(0); // Return empty bytes on error
    }
  }

  /// Saves an asset at the specified path
  Future<void> saveAssetByPath(String path, String data) async {
    try {
      await FileStorageService.instance.saveAssetByPath(path, data);
      print('Asset saved successfully: $path');
      print('Data size: ${data.length} bytes');
    } catch (e) {
      print('Error saving asset: $e');
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
  Future<String> getAssetRefPath(String assetPath) async {
    return await FileStorageService.instance.getBaseLocalAssetPath() +
        assetPath;
  }
}