import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'storage_interface.dart';

/// Implementation of storage for non-web platforms using the file system
class StorageImplementationIO implements StorageInterface {
  /// Get the app's document directory
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
  
  /// Get the assets folder path
  Future<String> get _assetsPath async {
    final localPath = await _localPath;
    final assetsDir = Directory(path.join(localPath, 'assets'));
    
    // Create assets directory if it doesn't exist
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    
    return assetsDir.path;
  }
  
  @override
  Future<void> saveAsset(String assetPath, String data) async {
    final basePath = await _assetsPath;
    final fullPath = path.join(basePath, assetPath);
    
    // Ensure parent directory exists
    final parentDir = Directory(path.dirname(fullPath));
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    
    // Write file
    final file = File(fullPath);
    await file.writeAsString(data);
    
    print('Asset saved to disk: $assetPath');
  }
  
  @override
  Future<String> getAsset(String assetPath) async {
    final basePath = await _assetsPath;
    final fullPath = path.join(basePath, assetPath);
    
    final file = File(fullPath);
    
    if (await file.exists()) {
      // Read and return file contents
      return await file.readAsString();
    } else {
      print('Asset not found on disk: $assetPath');
      return '';
    }
  }
  
  @override
  Future<bool> deleteAsset(String assetPath) async {
    final basePath = await _assetsPath;
    final fullPath = path.join(basePath, assetPath);
    
    final file = File(fullPath);
    
    if (await file.exists()) {
      await file.delete();
      print('Asset deleted from disk: $assetPath');
      return true;
    } else {
      print('Asset not found on disk for deletion: $assetPath');
      return false;
    }
  }
  
  @override
  Future<void> close() async {
    // No resources to close for file system implementation
  }
}