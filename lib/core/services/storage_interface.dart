/// Interface for platform-specific storage implementations
abstract class StorageInterface {

  Future<String> getBaseLocalAssetPath();
  /// Save asset data by path
  Future<void> saveAsset(String assetPath, String data);
  
  /// Get asset data by path
  Future<String> getAsset(String assetPath);
  
  /// Delete asset by path
  Future<bool> deleteAsset(String assetPath);
  
  /// Close any resources
  Future<void> close();
}