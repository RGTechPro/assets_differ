/// Interface for platform-specific storage implementations
abstract class StorageInterface {
  /// Save asset data by path
  Future<void> saveAsset(String assetPath, String data);
  
  /// Get asset data by path
  Future<String> getAsset(String assetPath);
  
  /// Delete asset by path
  Future<bool> deleteAsset(String assetPath);
  
  /// Close any resources
  Future<void> close();
}

/// Factory function to create the appropriate storage implementation
///
/// This is implemented in both storage_io.dart and storage_web.dart
/// and will return the appropriate implementation based on the platform
external StorageInterface createStorageImplementation();