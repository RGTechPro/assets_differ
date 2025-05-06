import 'package:assets_differ/core/services/file_storage_service.dart';
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
        "path": "assets/logo.png",
        "hash": "abc123def",
        "url": "https://picsum.photos/id/1011/300/200",
        "priority": 0
      },
      {
        "path": "assets/menu/menu_icon.png",
        "hash": "def456ghi",
        "url": "https://picsum.photos/id/1025/100/100",
        "priority": 1
      },
      {
        "path": "assets/banners/home/banner1.jpg",
        "hash": "ghi789jkl",
        "url": "https://picsum.photos/id/1038/600/300",
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
        "path": "assets/images/logo.png",
        "hash": "xyz321uvw",
        "url": "https://picsum.photos/id/1050/300/200",
        "priority": 0
      },
      {
        "path": "assets/icons/menu/menu_icon.png",
        "hash": "uvw654rst",
        "url": "https://picsum.photos/id/1062/100/100",
        "priority": 2
      },
      {
        "path": "assets/dark_logo.png",
        "hash": "mno999pqr",
        "url": "https://picsum.photos/id/1071/300/200",
        "priority": 1
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
    try {
      final result = await FileStorageService.instance.deleteAssetByPath(path);
      if (result) {
        print('Asset deleted successfully: $path');
      } else {
        print('Asset not found or could not be deleted: $path');
      }
    } catch (e) {
      print('Error deleting asset: $e');
    }
  }

  @override
  Future<String> getAssetByPath(String path) async {
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
    }
  }

  @override
  Future<void> saveAssetByPath(String path, String data) async {
    try {
      await FileStorageService.instance.saveAssetByPath(path, data);
      print('Asset saved successfully: $path');
      print('Data size: ${data.length} bytes');
    } catch (e) {
      print('Error saving asset: $e');
    }
  }

  /// Clear all local assets and the local manifest
  Future<void> clearAllLocalAssets() async {
    try {
      // Step 1: Get the local manifest first to know which assets to delete
      final manifest = await getLocalManifest();
      
      // Step 2: Delete all the assets if we have a manifest
      if (manifest != null) {
        for (var asset in manifest.assets) {
          await deleteAssetByPath(asset.path);
          print('Deleted asset: ${asset.path}');
        }
      }
      
      // Step 3: Clear the manifest from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_manifestKey);
      
      print('All local assets and manifest cleared successfully');
    } catch (e) {
      print('Error clearing local assets: $e');
    }
  }
}
