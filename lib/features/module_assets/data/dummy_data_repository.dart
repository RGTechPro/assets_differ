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

  Future<Uint8List?> getAssetByPath(String path) async {
    PerformanceTracker.startTracking('DummyDataRepository.getAssetByPath');
    try {
      return await _localDataSource.getAssetByPath(path);
    } finally {
      PerformanceTracker.endTracking('DummyDataRepository.getAssetByPath');
    }
  }

  Future<String> getAssetRefPath(String path) async {
    return await _localDataSource.getAssetRefPath(path);
  }

  /// Clear local manifest from storage
  Future<void> clearLocalManifest() async {
    await _localDataSource.clearManifest();
  }

  /// Load image data from a URL
  Future<Uint8List> loadImageFromUrl(String url) async {
    PerformanceTracker.startTracking('DummyDataRepository.loadImageFromUrl');
    try {
      return await _remoteDataSource.loadImageFromUrl(url);
    } finally {
      PerformanceTracker.endTracking('DummyDataRepository.loadImageFromUrl');
    }
  }

  /// Save asset data by path
  Future<void> saveAssetByPath(String path, String data) async {
    PerformanceTracker.startTracking('DummyDataRepository.saveAssetByPath');
    try {
      await _localDataSource.saveAssetByPath(path, data);
    } finally {
      PerformanceTracker.endTracking('DummyDataRepository.saveAssetByPath');
    }
  }

  /// Delete all local data
  Future<void> deleteAllData() async {
    PerformanceTracker.startTracking('DummyDataRepository.deleteAllData');
    try {
      await _localDataSource.clearManifest();
      // Add any other data clearing operations here
    } finally {
      PerformanceTracker.endTracking('DummyDataRepository.deleteAllData');
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
