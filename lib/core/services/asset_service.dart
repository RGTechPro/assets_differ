import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/asset_models.dart';

/// Service responsible for handling asset operations
class AssetService {
  final String _baseApiUrl;
  final String _appVersion;
  final String _brandId;
  late final String _assetBasePath;
  late final Directory? _assetDirectory; // Made nullable to handle web
  
  // Singleton instance
  static AssetService? _instance;
  
  /// Get the singleton instance of AssetService
  static Future<AssetService> getInstance({
    required String baseApiUrl,
    required String appVersion,
    required String brandId,
  }) async {
    if (_instance == null) {
      _instance = AssetService._internal(
        baseApiUrl: baseApiUrl,
        appVersion: appVersion,
        brandId: brandId,
      );
      await _instance!._initialize();
    }
    return _instance!;
  }
  
  AssetService._internal({
    required String baseApiUrl,
    required String appVersion,
    required String brandId,
  }) : _baseApiUrl = baseApiUrl,
       _appVersion = appVersion,
       _brandId = brandId;
  
  /// Initialize the asset service by creating necessary directories
  Future<void> _initialize() async {
    if (kIsWeb) {
      // For web, we'll use a virtual path since actual file system isn't available
      _assetBasePath = 'assets';
      _assetDirectory = null; // No directory on web
    } else {
      // For mobile and desktop platforms, use the file system
      final appDir = await getApplicationDocumentsDirectory();
      _assetBasePath = '${appDir.path}/assets';
      _assetDirectory = Directory(_assetBasePath);
      
      if (!await _assetDirectory!.exists()) {
        await _assetDirectory!.create(recursive: true);
      }
    }
  }
  
  /// Fetch asset update info from the server for a specific module
  Future<AssetUpdateResponse> fetchAssetUpdates(String module) async {
    final Uri url = Uri.parse('$_baseApiUrl/assets/updates');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'version': _appVersion,
        'brand_id': _brandId,
        'module': module,
      }),
    );
    
    if (response.statusCode == 200) {
      return AssetUpdateResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to fetch asset updates: ${response.statusCode}');
    }
  }
  
  /// Download a CDN asset and save it locally
  Future<void> downloadAsset(CdnAsset asset) async {
    final Uri url = Uri.parse(asset.url);
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        if (kIsWeb) {
          // For web, we'll handle storage elsewhere via the storage service
          print('Downloaded asset: ${asset.path} (web mode)');
        } else {
          // For mobile/desktop platforms, save to file system
          final File file = File('$_assetBasePath/${asset.path}');
          
          // Ensure parent directory exists
          final Directory parent = Directory(file.parent.path);
          if (!await parent.exists()) {
            await parent.create(recursive: true);
          }
          
          await file.writeAsBytes(response.bodyBytes);
          print('Downloaded and saved asset: ${asset.path}');
        }
      } else {
        throw Exception('Failed to download asset: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading asset ${asset.path}: $e');
      rethrow;
    }
  }
  
  /// Download a list of assets
  Future<void> downloadAssets(List<CdnAsset> assets) async {
    if (assets.isEmpty) {
      print('No assets to download.');
      return;
    }
    
    print('Downloading ${assets.length} assets...');
    
    // Sort assets by priority (lower priority number downloaded first)
    final sortedAssets = List<CdnAsset>.from(assets)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    
    // Download assets sequentially
    for (final asset in sortedAssets) {
      await downloadAsset(asset);
    }
  }
  
  /// Apply changes from an asset update response
  Future<void> applyAssetChanges(AssetUpdateResponse updateResponse, String module) async {
    // Process added or updated assets
    final assetsToDownload = <CdnAsset>[];
    
    // Handle added assets
    updateResponse.changes.added.forEach((path, asset) {
      assetsToDownload.add(asset);
    });
    
    // Handle updated assets
    updateResponse.changes.updated.forEach((path, asset) {
      assetsToDownload.add(asset);
    });
    
    // Remove deleted assets
    if (!kIsWeb) {
      // Only perform file operations on non-web platforms
      updateResponse.changes.removed.forEach((path, asset) {
        final File file = File('$_assetBasePath/${asset.path}');
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
    }
    
    // Download all new or updated assets
    await downloadAssets(assetsToDownload);
    
    // Save the current version info for this module
    await _saveModuleVersion(module, updateResponse.version);
  }
  
  /// Save the current version information for a module
  Future<void> _saveModuleVersion(String module, String version) async {
    if (kIsWeb) {
      // For web, we'll handle version storage elsewhere
      print('Saved version for $module: $version (web mode)');
      return;
    }
    
    // For mobile/desktop platforms
    final File versionFile = File('$_assetBasePath/$module/version.json');
    final Directory parent = Directory(versionFile.parent.path);
    
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    
    await versionFile.writeAsString(jsonEncode({
      'version': version,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }
  
  /// Get the current version for a module
  Future<String?> getModuleVersion(String module) async {
    if (kIsWeb) {
      // For web, you might want to implement a version check using localStorage
      // or IndexedDB via the StorageImplementationWeb class
      return null;
    }
    
    final File versionFile = File('$_assetBasePath/$module/version.json');
    
    if (await versionFile.exists()) {
      final String content = await versionFile.readAsString();
      final Map<String, dynamic> versionData = jsonDecode(content) as Map<String, dynamic>;
      return versionData['version'] as String;
    }
    
    return null;
  }
  
  /// Check if an asset exists locally
  bool assetExists(String path) {
    if (kIsWeb) {
      // For web, always return true and let the storage implementation handle it
      return true;
    }
    
    final File assetFile = File('$_assetBasePath/$path');
    return assetFile.existsSync();
  }
  
  /// Get an asset's file path
  String getAssetPath(String path) {
    return '$_assetBasePath/$path';
  }
  
  /// Clean up old or unused assets
  Future<void> cleanupAssets() async {
    // Implement cleanup logic for old or unused assets
    // This can be based on access time, module versions, etc.
  }
}