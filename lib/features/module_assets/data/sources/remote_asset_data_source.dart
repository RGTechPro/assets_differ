import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:assets_differ/core/utils/performance_tracker.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';

/// Handles all remote data operations for assets
class RemoteAssetDataSource {
  final String baseUrl = 'https://asset-differ.free.beeceptor.com';

  // JSON data for version 1.0.0
  final Map<String, dynamic> _v1Json = {
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
        "path": "assets/menu_icon.png",
        "hash": "def456gh9",
        "url": "https://picsum.photos/id/1020/100/100",
        "priority": 1
      },
      {
        "path": "assets/banner1.png",
        "hash": "ghi789jkl",
        "url": "https://picsum.photos/id/1038/600/300",
        "priority": 2
      }
    ]
  };

  // JSON data for version 2.0.0
  final Map<String, dynamic> _v2Json = {
    "version": "1.1.0",
    "module": "lobby",
    "assets": [
      {
        "path": "assets/logo.png",
        "hash": "abc123def",
        "url": "https://picsum.photos/id/1011/300/200",
        "priority": 0
      },
      {
        "path": "assets/menu_icon.png",
        "hash": "def456gh9",
        "url": "https://picsum.photos/id/1020/100/100",
        "priority": 1
      },
      {
        "path": "assets/banner1.png",
        "hash": "ghi789jkl",
        "url": "https://picsum.photos/id/1038/600/300",
        "priority": 2
      }
    ]
  };

  // JSON data for version 3.0.0
  final Map<String, dynamic> _v3Json = {
    "version": "1.2.0",
    "module": "lobby",
    "assets": [
      {
        "path": "assets/logo.png",
        "hash": "abc1235efj",
        "url": "https://picsum.photos/id/1012/300/200",
        "priority": 0
      },
      {
        "path": "assets/menu_icon.png",
        "hash": "def456ghi",
        "url": "https://picsum.photos/id/1025/100/100",
        "priority": 1
      },
      {
        "path": "assets/banner1.png",
        "hash": "ghi789jkl",
        "url": "https://picsum.photos/id/1038/600/300",
        "priority": 2
      }
    ]
  };

  /// Fetch asset data based on version
  /// Returns a Future with the AssetManifest for the requested version
  Future<AssetManifest> getRemoteManifest(String version) async {

    return _getFallbackManifest(version);
    
    PerformanceTracker.startTracking('RemoteAssetDataSource.getRemoteManifest');
    print('Fetching remote manifest for version: $version');

    String endpoint;

    // Determine the endpoint based on the version
    switch (version) {
      case '1.0.0':
        endpoint = '/getRemoteManifest/v1';
        break;
      case '1.1.0':
        endpoint = '/getRemoteManifest/v2';
        break;
      case '1.2.0':
        endpoint = '/getRemoteManifest/v3';
        break;
      default:
        endpoint = '/getRemoteManifest/v1'; // Default to latest version
    }

    final client = http.Client();

    try {
      // Make the HTTP request to the API
      PerformanceTracker.startTracking('RemoteAssetDataSource.apiHttpRequest');
      
      final response = await client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      PerformanceTracker.endTracking('RemoteAssetDataSource.apiHttpRequest');

      if (response.statusCode == 200) {
        // Parse the JSON response
        PerformanceTracker.startTracking('RemoteAssetDataSource.parseJsonResponse');
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final manifest = AssetManifest.fromJson(jsonData);
        PerformanceTracker.endTracking('RemoteAssetDataSource.parseJsonResponse');
        PerformanceTracker.endTracking('RemoteAssetDataSource.getRemoteManifest');
        return manifest;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        // Fallback to local JSON data if API fails
        final manifest = _getFallbackManifest(version);
        return manifest;
      }
    } catch (e) {
      print('Network error fetching remote manifest: $e');
      // Fallback to local JSON data if there's a network error
      final manifest = _getFallbackManifest(version);
      return manifest;
    } finally {
      client.close();
    }
  }

  /// Fallback method to get manifest from local JSON if API fails
  AssetManifest _getFallbackManifest(String version) {
    print('Using fallback data for version: $version');
    switch (version) {
      case '1.0.0':
        return AssetManifest.fromJson(_v1Json);
      case '1.1.0':
        return AssetManifest.fromJson(_v2Json);
      case '1.2.0':
        return AssetManifest.fromJson(_v3Json);
      default:
        return AssetManifest.fromJson(_v3Json);
    }
  }

  /// Load image data from a network URL
  Future<Uint8List> loadImageFromUrl(String imageUrl) async {
    PerformanceTracker.startTracking('RemoteAssetDataSource.loadImageFromUrl');
    final client = http.Client();
    try {
      PerformanceTracker.startTracking('RemoteAssetDataSource.imageHttpRequest');
      final http.Response response = await client.get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 30));
      PerformanceTracker.endTracking('RemoteAssetDataSource.imageHttpRequest');

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw HttpException(
            'Failed to load image. Status code: ${response.statusCode}',
            uri: Uri.parse(imageUrl));
      }
    } finally {
      client.close();
      PerformanceTracker.endTracking('RemoteAssetDataSource.loadImageFromUrl');
    }
  }
}

/// Custom exception for HTTP-related errors
class HttpException implements Exception {
  final String message;
  final Uri? uri;

  HttpException(this.message, {this.uri});

  @override
  String toString() => 'HttpException: $message${uri != null ? ' ($uri)' : ''}';
}