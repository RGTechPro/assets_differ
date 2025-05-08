import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:assets_differ/core/utils/performance_tracker.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:assets_differ/features/module_assets/data/sources/local_asset_data_source.dart';
import 'package:assets_differ/features/module_assets/data/sources/remote_asset_data_source.dart';

/// Repository for serving static dummy data for testing
/// This class delegates operations to the appropriate data source
class DummyDataRepository {
  final LocalAssetDataSource _localDataSource;
  final RemoteAssetDataSource _remoteDataSource;

  /// Constructor with dependency injection
  DummyDataRepository({
    LocalAssetDataSource? localDataSource,
    RemoteAssetDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource ?? LocalAssetDataSource(),
        _remoteDataSource = remoteDataSource ?? RemoteAssetDataSource();

  Future<AssetManifest> getRemoteManifest(String version) async {
    return await _remoteDataSource.getRemoteManifest(version);
  }

  Future<AssetManifest?> getLocalManifest() async {
    return await _localDataSource.getLocalManifest();
  }

  Future<void> setLocalManifest(AssetManifest manifest) async {
    await _localDataSource.setLocalManifest(manifest);
  }

  Future<void> deleteAssetByPath(String path) async {
    await _localDataSource.deleteAssetByPath(path);
  }

  Future<String> getAssetByPath(String path) async {
    PerformanceTracker.startTracking('DummyDataRepository.getAssetByPath');
    try {
      return await _localDataSource.getAssetByPath(path);
    } finally {
      PerformanceTracker.endTracking('DummyDataRepository.getAssetByPath');
    }
  }

  Future<String> baseLocalAssetPath() async {
    return await _localDataSource.baseLocalAssetPath();
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
      await _localDataSource.clearManifest();

      print('All local assets and manifest cleared successfully');
    } catch (e) {
      print('Error clearing local assets: $e');
    }
  }

  /// Download and save a single asset based on its type
  Future<ImageUploadResponse> downloadAndSaveAsset(AssetItem asset) async {
    PerformanceTracker.startTracking('DummyDataRepository.downloadAndSaveAsset');
    
    try {
      // Download the image data as bytes
      PerformanceTracker.startTracking('RemoteDataSource.loadImageFromUrl');
      final Uint8List imageBytes =
          await _remoteDataSource.loadImageFromUrl(asset.url);
      PerformanceTracker.endTracking('RemoteDataSource.loadImageFromUrl');
      
      // Convert bytes to base64 string for storage
      PerformanceTracker.startTracking('Base64Encode');
      final String base64Image = base64Encode(imageBytes);
      PerformanceTracker.endTracking('Base64Encode');
      
      // Save the image data to local storage
      await _localDataSource.saveAssetByPath(asset.path, base64Image);
      
      return ImageUploadResponse(
        imageBytesLength: imageBytes.length,
        isSuccess: true,
      );
    } finally {
      PerformanceTracker.endTracking('DummyDataRepository.downloadAndSaveAsset');
    }
  }
}

class ImageUploadResponse {
  final int imageBytesLength;
  final bool isSuccess;

  ImageUploadResponse({
    required this.imageBytesLength,
    required this.isSuccess,
  });
}
