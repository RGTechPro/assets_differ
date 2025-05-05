
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:get/get.dart';

/// Base interface for asset repositories
abstract class BaseAssetRepository {
  /// Fetch asset data for a specific version
  Future<AssetManifest> getRemoteManifest(String version);

  /// Fetch asset data for a specific version
  Future<AssetManifest?> getLocalManifest();

    /// Fetch asset data for a specific version
  Future<void> setLocalManifest(AssetManifest manifest);


  Future<void> saveAssetByPath(String path, String data);


  Future<void> deleteAssetByPath(String path);

  Future<String> getAssetByPath(String path);

}