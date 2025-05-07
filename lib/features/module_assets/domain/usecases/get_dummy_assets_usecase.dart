import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';
import 'package:assets_differ/features/module_assets/data/repository/repository_interface.dart';

/// Use case to provide and manage DummyAssets
class GetDummyAssetsUseCase {
  final PlatformInfo _platformInfo;
  final BaseAssetRepository _repository;
  final _logger = AssetLogger('GetDummyAssetsUseCase');

  // Observable asset state
  final Rx<DummyAssets> _dummyAssets = DummyAssets(
    logoImage: kZeroPixel,
    menuIcon: kZeroPixel,
    bannerImage: kZeroPixel,
  ).obs;

  GetDummyAssetsUseCase(this._repository, this._platformInfo);

  /// The current DummyAssets as an observable
  Rx<DummyAssets> get dummyAssets => _dummyAssets;

  /// Execute the use case to get DummyAssets as an Observable
  Future<DummyAssets> execute() async {
    try {
      // First, load local manifest to get the current version
      final AssetManifest? localManifest = await _repository.getLocalManifest();

      // Use the repository to fetch remote data using the current version
      final AssetManifest remoteManifest =
          await _repository.getRemoteManifest(_platformInfo.version);

      // Analyze the differences between local and remote manifests
      final ManifestDifference diff =
          _compareManifests(localManifest, remoteManifest);

      // P0 assets need to be processed immediately
      await _saveAssetsToLocalStorage(diff.priorityAssets.p0);

      // Generate the initial assets map with P0 assets
      final dummyAssets = await _generateDummyAssets(remoteManifest, 0);
      _dummyAssets.value = dummyAssets;

      // Process remaining assets in the background
      _updateAssetsInBackground(diff, remoteManifest);

      return dummyAssets;
    } catch (e, stackTrace) {
      _logger.error('Failed to execute GetDummyAssetsUseCase', e, stackTrace);
      rethrow;
    }
  }

  /// Compare local and remote manifests to identify differences
  ManifestDifference _compareManifests(
      AssetManifest? localManifest, AssetManifest remoteManifest) {
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

  /// Process remaining assets and update in background
  Future<void> _updateAssetsInBackground(
      ManifestDifference diff, AssetManifest remoteManifest) async {
    try {
      // Process P1 and P2 assets in order
      await _saveAssetsToLocalStorage(diff.priorityAssets.p1);
      await _saveAssetsToLocalStorage(diff.priorityAssets.p2);

      // Remove deleted assets
      if (diff.removedAssets.isNotEmpty) {
        await _deleteRemovedAssets(diff.removedAssets);
      }

      // Save the updated manifest to local storage
      await _repository.setLocalManifest(remoteManifest);

      // Update the asset map with all priorities
      final dummyAssets = await _generateDummyAssets(remoteManifest, null);
      _dummyAssets.value = dummyAssets;

      _logger.info('Background asset update complete');
    } catch (e, stackTrace) {
      _logger.error('Error in background asset update', e, stackTrace);
    }
  }

  /// Generate a DummyAssets object from assets in the manifest
  /// If priorityFilter is provided, only includes assets with that priority
  Future<DummyAssets> _generateDummyAssets(
    AssetManifest manifest,
    int? priorityFilter,
  ) async {
    final String localPath = await _repository.baseLocalAssetPath();

    Map<String, String> assetMap = {};

    // Filter assets by priority if needed
    final assetsToInclude = priorityFilter != null
        ? manifest.assets.where((e) => e.priority == priorityFilter)
        : manifest.assets;

    // Build the asset map
    for (var asset in assetsToInclude) {
      assetMap[asset.path] = localPath + asset.path;
    }

    return DummyAssets.fromAssetMap(assetMap);
  }

  /// Save assets to local storage
  Future<void> _saveAssetsToLocalStorage(List<AssetItem> assetList) async {
    if (assetList.isEmpty) return;

    _logger.info('Saving ${assetList.length} assets to local storage');

    // Process each asset in parallel for efficiency
    await Future.wait(
      assetList.map((asset) => _downloadAndSaveAsset(asset)),
    );
  }

  /// Download and save a single asset based on its type
  Future<void> _downloadAndSaveAsset(AssetItem asset) async {
    try {
      _logger.debug('Downloading image: ${asset.url}');

      ImageUploadResponse response =
          await _repository.downloadAndSaveAsset(asset);

      _logger.debug(
          'Saved image: ${asset.path} (${response.imageBytesLength} bytes)');
    } catch (e, stackTrace) {
      _logger.error('Failed to process asset ${asset.path}', e, stackTrace);
    }
  }

  /// Delete assets that have been removed from the manifest
  Future<void> _deleteRemovedAssets(List<AssetItem> removedAssets) async {
    if (removedAssets.isEmpty) return;

    _logger.info('Deleting ${removedAssets.length} removed assets');

    // Delete each asset from storage
    for (var asset in removedAssets) {
      try {
        await _repository.deleteAssetByPath(asset.path);
        _logger.debug('Deleted asset: ${asset.path}');
      } catch (e) {
        _logger.error('Failed to delete asset ${asset.path}', e);
      }
    }
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

/// Simple logger class for asset operations
class AssetLogger {
  final String _tag;

  AssetLogger(this._tag);

  void debug(String message) {
    if (kDebugMode) print('[$_tag] DEBUG: $message');
  }

  void info(String message) {
    print('[$_tag] INFO: $message');
  }

  void warn(String message) {
    print('[$_tag] WARN: $message');
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    print('[$_tag] ERROR: $message${error != null ? ' - $error' : ''}');
    if (kDebugMode && stackTrace != null) {
      print('[$_tag] STACK: $stackTrace');
    }
  }
}

class PlatformInfo {
  final String version;

  PlatformInfo({
    required this.version,
  });
}
