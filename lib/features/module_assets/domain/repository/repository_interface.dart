import '../../data/models/asset_manifest.dart';

/// Interface defining the contract for asset repositories
abstract class BaseAssetRepository {
  /// Fetches the asset manifest from a remote source
  Future<AssetManifest> getRemoteManifest(String version);

  /// Retrieves the locally stored asset manifest
  Future<AssetManifest?> getLocalManifest();

  /// Stores the asset manifest locally
  Future<void> setLocalManifest(AssetManifest manifest);

  /// Deletes an asset at the specified path
  Future<void> deleteAssetByPath(String path);

  /// Retrieves an asset at the specified path
  Future<String> getAssetByPath(String path);

  /// Download and save a single asset based on its type
  Future<ImageUploadResponse> downloadAndSaveAsset(AssetItem asset);

  /// Gets the base path for storing local assets
  Future<String> baseLocalAssetPath();
}

class ImageUploadResponse {
  final int imageBytesLength;
  final bool isSuccess;

  ImageUploadResponse({
    required this.imageBytesLength,
    required this.isSuccess,
  });
}
