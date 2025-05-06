import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:get/get.dart';
import '../../../module_assets/presentation/controllers/assets_controller.dart';
import '../../data/repository/repository_interface.dart';

/// Use case to provide DummyAssets
class GetDummyAssetsUseCase {
  final PlatformInfo _platformInfo;
  final BaseAssetRepository _repository;
  
  GetDummyAssetsUseCase(this._repository, this._platformInfo);

  final Completer<bool> _p0completer = Completer<bool>();

  Future<bool> get isP0Completed => _p0completer.future;

  final Completer<bool> _p1p2completer = Completer<bool>();

  Future<bool> get isP1P2Completed => _p1p2completer.future;

    

  // final Rx<DummyAssets> _dummyAssets = DummyAssets(
  //       sectionOneAssetList: [],
  //       sectionTwoAssetList: [],
  //       sectionThreeAssetList: [],
  //     ).obs;

  // Rx<DummyAssets> get dummyAssets => _dummyAssets;

  
  /// Execute the use case to get DummyAssets as an Observable
  Future<DummyAssets> execute() async {
    // First, load local manifest to get the current version
    final AssetManifest? localManifest = await _repository.getLocalManifest();
    
    
    // Use the repository to fetch remote data using the current version
    final AssetManifest remoteManifest = await _repository.getRemoteManifest("1.0.0");
    
    // Extract assets by priority
    List<AssetItem> p0Assets = [];
    List<AssetItem> p1Assets = [];
    List<AssetItem> p2Assets = [];
    
    // Create lists to track differences between local and remote manifests
    List<AssetItem> newAssetItemList = [];
    List<AssetItem> removedAssetItemList = [];
    List<AssetItem> updatedAssetItemList = [];
    
    // Compare local and remote manifests if local manifest exists
    if (localManifest != null) {
      // Create maps for easier lookup
      final Map<String, AssetItem> localAssetMap = {
        for (var asset in localManifest.assets) asset.path: asset
      };
      
      final Map<String, AssetItem> remoteAssetMap = {
        for (var asset in remoteManifest.assets) asset.path: asset
      };
      
      // Find new assets (in remote but not in local)
      for (var asset in remoteManifest.assets) {
        if (!localAssetMap.containsKey(asset.path)) {
          newAssetItemList.add(asset);
        } else {
          // Check if existing asset has been updated (different hash or priority)
          final localAsset = localAssetMap[asset.path]!;
          if (localAsset.hash != asset.hash || localAsset.priority != asset.priority) {
            updatedAssetItemList.add(asset);
          }
        }
      }
      
      // Find removed assets (in local but not in remote)
      for (var asset in localManifest.assets) {
        if (!remoteAssetMap.containsKey(asset.path)) {
          removedAssetItemList.add(asset);
        }
      }
    } else {
      // If no local manifest exists, all remote assets are new
      newAssetItemList = remoteManifest.assets;
      print('No local manifest found. All ${newAssetItemList.length} assets are new.');
    }
    
    // Categorize new and updated assets by priority
    for (var asset in [...newAssetItemList, ...updatedAssetItemList]) {
      switch (asset.priority) {
        case 0:
          p0Assets.add(asset);
          break;
        case 1:
          p1Assets.add(asset);
          break;
        case 2:
          p2Assets.add(asset);
          break;
        default:
          print('Asset ${asset.path} has unconventional priority: ${asset.priority}');
          break;
      }
    }

    // Save the new and updated assets to local storage
    await _saveAssetsToLocalStorage(p0Assets);

    _p0completer.complete(true);  
    // Update the observable with new data
    // _dummyAssets.value = DummyAssets(
    //   sectionOneAssetList: p0Assets.map((e)=> e.path).toList(),
    //   sectionTwoAssetList: [],
    //   sectionThreeAssetList: [],
    // );
    

    await _saveAssetsToLocalStorage(p1Assets);
    await _saveAssetsToLocalStorage(p2Assets);

        // Delete removed assets from local storage
    if (removedAssetItemList.isNotEmpty) {
      await _deleteRemovedAssets(removedAssetItemList);
    }
    
    // Save the updated manifest to local storage
    await _repository.setLocalManifest(remoteManifest);
       // Update the observable with new data
    // _dummyAssets.value = DummyAssets(
    //   sectionOneAssetList: p0Assets.map((e)=> e.path).toList(),
    //   sectionTwoAssetList: p1Assets.map((e)=> e.path).toList(),
    //   sectionThreeAssetList: p2Assets.map((e)=> e.path).toList(),
    // );

    _p1p2completer.complete(true);
  }
  
  /// Save new and updated assets to local storage
  Future<void> _saveAssetsToLocalStorage(List<AssetItem> assetList) async {
    // Save new assets to local storage
    if (assetList.isNotEmpty) {
      
      // Process and save each new asset
      for (var asset in assetList) {
        await _downloadAndSaveAsset(asset);
      }
    }
    

  }
  
  /// Download and save a single asset based on its type
  Future<void> _downloadAndSaveAsset(AssetItem asset) async {
    try {
      final String path = asset.path.toLowerCase();
      
      // Check if this is an image asset
      if (path.endsWith('.png') || path.endsWith('.jpg') || 
          path.endsWith('.jpeg') || path.endsWith('.gif') || 
          path.endsWith('.webp') || path.endsWith('.svg')) {
        
        print('Downloading image: ${asset.url}');
        
        // Download the image data as bytes
        final Uint8List imageBytes = await loadImageFromUrl(asset.url);
        
        // Convert bytes to base64 string for storage
        final String base64Image = base64Encode(imageBytes);
        
        // Save the image data to local storage
        await _repository.saveAssetByPath(asset.path, base64Image);
        
        print('Successfully saved image: ${asset.path} (${imageBytes.length} bytes)');
      } else {
        // Handle other types of assets or use placeholder content
        final String assetContent = 'Content for ${asset.path} with hash ${asset.hash}';
        await _repository.saveAssetByPath(asset.path, assetContent);
        
        print('Saved placeholder content for: ${asset.path}');
      }
    } catch (e) {
      // Log the error but continue with other assets
      print('Failed to process asset ${asset.path}: $e');
    }
  }

  /// Delete assets that have been removed from the manifest
  Future<void> _deleteRemovedAssets(List<AssetItem> removedAssets) async {
    if (removedAssets.isEmpty) return;

    // Delete each asset from storage
    for (var asset in removedAssets) {
      try {
        await _repository.deleteAssetByPath(asset.path);
        print('Successfully deleted asset: ${asset.path}');
      } catch (e) {
        print('Failed to delete asset ${asset.path}: $e');
      }
    }
    
    print('Asset deletion completed');
  }

  /// Load image data from a network URL into bytes
  /// 
  /// Parameters:
  /// - imageUrl: The URL of the image to load
  /// 
  /// Returns:
  /// - Future<Uint8List>: The image data as bytes
  Future<Uint8List> loadImageFromUrl(String imageUrl) async {
    try {
      // Make an HTTP GET request to the provided URL
      final http.Response response = await http.get(Uri.parse(imageUrl));
      
      // Check if the request was successful
      if (response.statusCode == 200) {
        // Return the body as bytes
        return response.bodyBytes;
      } else {
        // Log error and throw exception with status code
        print('Failed to load image from $imageUrl. Status code: ${response.statusCode}');
        throw Exception('Failed to load image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Log and rethrow any errors that occur during the request
      print('Error loading image from $imageUrl: $e');
      throw Exception('Error loading image: $e');
    }
  }
}

class PlatformInfo {
  final String version;

  PlatformInfo({required this.version,});
}