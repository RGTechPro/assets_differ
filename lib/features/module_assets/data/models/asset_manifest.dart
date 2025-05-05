import 'dart:convert';

/// Model class representing an asset in the manifest
class AssetItem {
  final String path;
  final String hash;
  final String url;
  final int priority;
  
  AssetItem({
    required this.path,
    required this.hash,
    required this.url,
    required this.priority,
  });
  
  /// Create an AssetItem from JSON
  factory AssetItem.fromJson(Map<String, dynamic> json) {
    return AssetItem(
      path: json['path'] as String,
      hash: json['hash'] as String,
      url: json['url'] as String,
      priority: json['priority'] as int,
    );
  }
  
  /// Convert AssetItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'hash': hash,
      'url': url,
      'priority': priority,
    };
  }
  
  /// Create a copy of this AssetItem with the given fields replaced
  AssetItem copyWith({
    String? path,
    String? hash,
    String? url,
    int? priority,
  }) {
    return AssetItem(
      path: path ?? this.path,
      hash: hash ?? this.hash,
      url: url ?? this.url,
      priority: priority ?? this.priority,
    );
  }
}

/// Model class representing the asset manifest
class AssetManifest {
  final String version;
  final String module;
  final List<AssetItem> assets;
  final String? lastUpdated;
  
  AssetManifest({
    required this.version,
    required this.module,
    required this.assets,
    this.lastUpdated,
  });
  
  /// Create an AssetManifest from JSON
  factory AssetManifest.fromJson(Map<String, dynamic> json) {
    final assetList = (json['assets'] as List<dynamic>)
        .map((assetJson) => AssetItem.fromJson(assetJson as Map<String, dynamic>))
        .toList();
    
    return AssetManifest(
      version: json['version'] as String,
      module: json['module'] as String,
      assets: assetList,
      lastUpdated: json['lastUpdated'] as String?,
    );
  }
  
  /// Create an AssetManifest from a JSON string
  factory AssetManifest.fromJsonString(String jsonString) {
    return AssetManifest.fromJson(
      json.decode(jsonString) as Map<String, dynamic>
    );
  }
  
  /// Convert AssetManifest to JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'module': module,
      'assets': assets.map((asset) => asset.toJson()).toList(),
      if (lastUpdated != null) 'lastUpdated': lastUpdated,
    };
  }
  
  /// Convert AssetManifest to a JSON string
  String toJsonString() {
    return json.encode(toJson());
  }
  
  /// Create a copy of this AssetManifest with the given fields replaced
  AssetManifest copyWith({
    String? version,
    String? module,
    List<AssetItem>? assets,
    String? lastUpdated,
  }) {
    return AssetManifest(
      version: version ?? this.version,
      module: module ?? this.module,
      assets: assets ?? this.assets,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  /// Get assets with a specific priority
  List<AssetItem> getAssetsByPriority(int priority) {
    return assets.where((asset) => asset.priority == priority).toList();
  }
  
  /// Get URLs of assets with a specific priority
  List<String> getAssetUrlsByPriority(int priority) {
    return getAssetsByPriority(priority).map((asset) => asset.url).toList();
  }
}