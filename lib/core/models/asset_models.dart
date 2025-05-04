import 'dart:convert';

/// Model representing an asset in the developer-managed manifest
class AssetManifestItem {
  final String path;
  final int priority;
  
  AssetManifestItem({
    required this.path,
    required this.priority,
  });
  
  factory AssetManifestItem.fromJson(Map<String, dynamic> json) {
    return AssetManifestItem(
      path: json['path'] as String,
      priority: json['priority'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'priority': priority,
    };
  }
}

/// Model representing the developer-managed manifest
class AssetManifest {
  final String version;
  final List<AssetManifestItem> assets;
  
  AssetManifest({
    required this.version,
    required this.assets,
  });
  
  factory AssetManifest.fromJson(Map<String, dynamic> json) {
    return AssetManifest(
      version: json['version'] as String,
      assets: (json['assets'] as List)
          .map((item) => AssetManifestItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
  
  factory AssetManifest.fromString(String jsonString) {
    return AssetManifest.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'assets': assets.map((asset) => asset.toJson()).toList(),
    };
  }
}

/// Model representing a CDN asset in the runtime manifest
class CdnAsset {
  final String path;
  final String hash;
  final String url;
  final int priority;
  
  CdnAsset({
    required this.path,
    required this.hash,
    required this.url,
    required this.priority,
  });
  
  factory CdnAsset.fromJson(Map<String, dynamic> json) {
    return CdnAsset(
      path: json['path'] as String,
      hash: json['hash'] as String,
      url: json['url'] as String,
      priority: json['priority'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'hash': hash,
      'url': url,
      'priority': priority,
    };
  }
}

/// Model representing the CDN manifest
class CdnManifest {
  final String version;
  final String module;
  final List<CdnAsset> assets;
  
  CdnManifest({
    required this.version,
    required this.module,
    required this.assets,
  });
  
  factory CdnManifest.fromJson(Map<String, dynamic> json) {
    return CdnManifest(
      version: json['version'] as String,
      module: json['module'] as String,
      assets: (json['assets'] as List)
          .map((item) => CdnAsset.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
  
  factory CdnManifest.fromString(String jsonString) {
    return CdnManifest.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'module': module,
      'assets': assets.map((asset) => asset.toJson()).toList(),
    };
  }
}

/// Model representing asset changes from the backend
class AssetChanges {
  final Map<String, CdnAsset> added;
  final Map<String, CdnAsset> updated;
  final Map<String, CdnAsset> removed;
  
  AssetChanges({
    required this.added,
    required this.updated,
    required this.removed,
  });
  
  factory AssetChanges.fromJson(Map<String, dynamic> json) {
    Map<String, CdnAsset> parseNestedAssets(Map<String, dynamic> data) {
      final Map<String, CdnAsset> assets = {};
      
      void processLevel(Map<String, dynamic> currentLevel, String currentPath) {
        currentLevel.forEach((key, value) {
          if (value is Map<String, dynamic> && value.containsKey('hash')) {
            // This is an asset
            final String assetPath = '$currentPath$key';
            assets[assetPath] = CdnAsset(
              path: assetPath,
              hash: value['hash'] as String,
              url: value['url'] as String,
              priority: 0, // Default priority, might need adjustment
            );
          } else if (value is Map<String, dynamic>) {
            // This is a directory, go deeper
            processLevel(value as Map<String, dynamic>, '$currentPath$key/');
          }
        });
      }
      
      processLevel(data, '');
      return assets;
    }
    
    return AssetChanges(
      added: parseNestedAssets(json['add'] as Map<String, dynamic>),
      updated: parseNestedAssets(json['update'] as Map<String, dynamic>),
      removed: parseNestedAssets(json['remove'] as Map<String, dynamic>),
    );
  }
}

/// Model representing the asset update response from the backend
class AssetUpdateResponse {
  final String version;
  final String? assetsZipUrl;
  final AssetChanges changes;
  
  AssetUpdateResponse({
    required this.version,
    this.assetsZipUrl,
    required this.changes,
  });
  
  factory AssetUpdateResponse.fromJson(Map<String, dynamic> json) {
    return AssetUpdateResponse(
      version: json['version'] as String,
      assetsZipUrl: json['assets'] as String?,
      changes: AssetChanges.fromJson(json['changes'] as Map<String, dynamic>),
    );
  }
}