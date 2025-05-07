import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';

/// Handles all remote data operations for assets
class RemoteAssetDataSource {
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
        "path": "assets/menu_icon.png",
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

  /// Fetch asset data based on version
  /// Returns a Future with the AssetManifest for the requested version
  Future<AssetManifest> getRemoteManifest(String version) async {
    // Simulate fetching data from a remote source
    return Future.delayed(const Duration(milliseconds: 1), () {
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

  /// Load image data from a network URL
  Future<Uint8List> loadImageFromUrl(String imageUrl) async {
    final client = http.Client();
    try {
      final http.Response response = await client.get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw HttpException(
            'Failed to load image. Status code: ${response.statusCode}',
            uri: Uri.parse(imageUrl));
      }
    } finally {
      client.close();
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