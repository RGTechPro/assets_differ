import 'dart:typed_data';
import 'package:dynamic_asset_module/data/sources/local_asset_data_source.dart';
import 'package:dynamic_asset_module/data/sources/remote_asset_data_source.dart';
import 'package:flutter/foundation.dart';
import 'package:dynamic_asset_module/data/models/asset_manifest.dart';

/// Repository for serving static dummy data for testing
/// This class delegates operations to the appropriate data source
class DummyDataRepository {
  final LocalAssetDataSource _localDataSource;
  final RemoteAssetDataSource _remoteDataSource;

  /// Constructor with dependency injection
  DummyDataRepository({
    required LocalAssetDataSource localDataSource,
    required RemoteAssetDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;
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

  Future<Uint8List?> getAssetByPath(String path) async {
    return await _localDataSource.getAssetByPath(path);
  }

  /// Clear local manifest from storage
  Future<void> clearLocalManifest() async {
    await _localDataSource.clearManifest();
  }

  /// Load image data from a URL
  Future<Uint8List> loadImageFromUrl(String url) async {
    return await _remoteDataSource.loadImageFromUrl(url);
  }

  /// Save asset data by path
  Future<void> saveAssetByPath(String path, String data) async {
    await _localDataSource.saveAssetByPath(path, data);
  }

  /// Delete all local data
  Future<void> deleteAllData() async {
    await _localDataSource.clearManifest();
    // Add any other data clearing operations here
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
