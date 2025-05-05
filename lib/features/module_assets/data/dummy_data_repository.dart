import 'dart:convert';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'repository/repository_interface.dart';

/// Repository for serving static dummy data for testing
class DummyDataRepository implements BaseAssetRepository {
  /// Fetch asset data based on version
  /// Returns a Future with the JSON data for the requested version
  @override
  Future<AssetManifest> getRemoteManifest(String version) async {
    // Simulate fetching data from a remote source
    return Future.delayed(const Duration(seconds: 2), () {
      switch (version) {
        case '1.0.0':
          return AssetManifest.fromJson(v1Json);
        case '2.0.0':
          return AssetManifest.fromJson(v2Json);
        case '3.0.0':
          return AssetManifest.fromJson(v3Json);
        default:
          // Default to latest version if not found
          return AssetManifest.fromJson(v3Json);
      }
    });
  }

  // JSON data for version 1.0.0
  final Map<String, dynamic> v1Json = {
    "version": "1.0.0",
    "module": "lobby",
    "assets": [
      {
        "path": "images/logo.png",
        "hash": "h1v1",
        "url": "https://cdn.example.com/assets/v1.0.0/images/logo.png",
        "priority": 0
      },
      {
        "path": "icons/menu/menu_icon.png",
        "hash": "h2v1",
        "url": "https://cdn.example.com/assets/v1.0.0/icons/menu/menu_icon.png",
        "priority": 1
      },
      {
        "path": "banners/home/banner1.jpg",
        "hash": "h3v1",
        "url": "https://cdn.example.com/assets/v1.0.0/banners/home/banner1.jpg",
        "priority": 2
      }
    ]
  };

  // JSON data for version 2.0.0
  final Map<String, dynamic> v2Json = {
    "version": "2.0.0",
    "module": "lobby",
    "assets": [
      {
        "path": "images/logo.png",
        "hash": "h1v2",
        "url": "https://cdn.example.com/assets/v2.0.0/images/logo.png",
        "priority": 0
      },
      {
        "path": "icons/menu/menu_icon.png",
        "hash": "h2v2", 
        "url": "https://cdn.example.com/assets/v2.0.0/icons/menu/menu_icon.png",
        "priority": 1
      },
      {
        "path": "banners/home/banner1.jpg",
        "hash": "h3v2",
        "url": "https://cdn.example.com/assets/v2.0.0/banners/home/banner1.jpg",
        "priority": 2
      }
    ]
  };

  // JSON data for version 3.0.0
  final Map<String, dynamic> v3Json = {
    "version": "3.0.0",
    "module": "lobby",
    "assets": [
      {
        "path": "images/logo.png",
        "hash": "h1v3",
        "url": "https://cdn.example.com/assets/v3.0.0/images/logo.png",
        "priority": 0
      },
      {
        "path": "icons/menu/menu_icon.png",
        "hash": "h2v3",
        "url": "https://cdn.example.com/assets/v3.0.0/icons/menu/menu_icon.png",
        "priority": 1
      },
      {
        "path": "banners/home/banner1.jpg",
        "hash": "h3v3",
        "url": "https://cdn.example.com/assets/v3.0.0/banners/home/banner1.jpg",
        "priority": 2
      }
    ]
  };
  
  // Key for storing manifest in SharedPreferences
  static const String _manifestKey = 'local_asset_manifest';
  
  @override
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
  
  @override
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
  
  @override
  Future<void> deleteAssetByPath(String path) async {
    // Simulate deleting an asset
    return Future.delayed(const Duration(milliseconds: 500), () {
      // In a real implementation, this would delete a file
      print('Asset deleted: $path');
      // No actual deletion in dummy implementation
    });
  }
  
  @override
  Future<String> getAssetByPath(String path) async {
    // Simulate fetching asset data
    return Future.delayed(const Duration(milliseconds: 500), () {
      // In a real implementation, this would read from storage
      // Return a dummy asset content based on the path
      return 'Mock content for asset: $path';
    });
  }
  
  @override
  Future<void> saveAssetByPath(String path, String data) async {
    // Simulate saving asset data
    return Future.delayed(const Duration(milliseconds: 500), () {
      // In a real implementation, this would write to storage
      print('Asset saved: $path');
      print('Data size: ${data.length} bytes');
      // No actual saving in dummy implementation
    });
  }
}