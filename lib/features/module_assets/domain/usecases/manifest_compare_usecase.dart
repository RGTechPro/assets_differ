import 'package:assets_differ/features/module_assets/domain/usecases/generate_dummy_assets_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';

/// UseCase for comparing manifests to determine asset changes
class ManifestCompareUseCase {
  final _logger = AssetLogger('ManifestCompareUseCase');

  ManifestCompareUseCase();

  /// Compare local and remote manifests to identify differences
  ManifestDifference compareManifests(
      AssetManifest? localManifest, AssetManifest remoteManifest,) {
    final priorityAssets = _PriorityAssets();
    final List<AssetItem> newAssets = [];
    final List<AssetItem> removedAssets = [];
    final List<AssetItem> updatedAssets = [];

    if (localManifest == null) {
      // If no local manifest exists, all remote assets are new
      newAssets.addAll(remoteManifest.assets);
      _logger.info(
          'No local manifest found. All ${newAssets.length} assets are new.');
    } else {
      // Create maps for efficient lookups
      final Map<String, AssetItem> localAssetMap = {
        for (var asset in localManifest.assets) asset.path: asset
      };
      final Map<String, AssetItem> remoteAssetMap = {
        for (var asset in remoteManifest.assets) asset.path: asset
      };

      // Find new and updated assets
      for (var asset in remoteManifest.assets) {
        if (!localAssetMap.containsKey(asset.path)) {
          newAssets.add(asset);
        } else {
          // Check if existing asset has been updated
          final localAsset = localAssetMap[asset.path]!;
          if (localAsset.hash != asset.hash ||
              localAsset.priority != asset.priority) {
            updatedAssets.add(asset);
          }
        }
      }

      // Find removed assets
      for (var asset in localManifest.assets) {
        if (!remoteAssetMap.containsKey(asset.path)) {
          removedAssets.add(asset);
        }
      }
    }

    // Categorize new and updated assets by priority
    for (var asset in [...newAssets, ...updatedAssets]) {
      switch (asset.priority) {
        case 0:
          priorityAssets.p0.add(asset);
          break;
        case 1:
          priorityAssets.p1.add(asset);
          break;
        case 2:
          priorityAssets.p2.add(asset);
          break;
        default:
          _logger.warn(
              'Asset ${asset.path} has unconventional priority: ${asset.priority}');
          break;
      }
    }

    return ManifestDifference(
      priorityAssets: priorityAssets,
      newAssets: newAssets,
      removedAssets: removedAssets,
      updatedAssets: updatedAssets,
    );
  }
}

/// A class to hold assets categorized by priority
class _PriorityAssets {
  final List<AssetItem> p0 = [];
  final List<AssetItem> p1 = [];
  final List<AssetItem> p2 = [];
}

/// A class to represent differences between manifests
class ManifestDifference {
  final _PriorityAssets priorityAssets;
  final List<AssetItem> newAssets;
  final List<AssetItem> removedAssets;
  final List<AssetItem> updatedAssets;

  ManifestDifference({
    required this.priorityAssets,
    required this.newAssets,
    required this.removedAssets,
    required this.updatedAssets,
  });
}

// /// Simple logger class for asset operations
// class AssetLogger {
//   final String _tag;

//   AssetLogger(this._tag);

//   void debug(String message) {
//     if (kDebugMode) print('[$_tag] DEBUG: $message');
//   }

//   void info(String message) {
//     print('[$_tag] INFO: $message');
//   }

//   void warn(String message) {
//     print('[$_tag] WARN: $message');
//   }

//   void error(String message, [dynamic error, StackTrace? stackTrace]) {
//     print('[$_tag] ERROR: $message${error != null ? ' - $error' : ''}');
//     if (kDebugMode && stackTrace != null) {
//       print('[$_tag] STACK: $stackTrace');
//     }
//   }
// }