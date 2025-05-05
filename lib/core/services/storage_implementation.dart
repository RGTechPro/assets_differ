import 'package:assets_differ/core/services/storage_web_impl.dart';
import 'package:flutter/foundation.dart';
import 'storage_interface.dart';

// Import the implementations
import 'storage_io.dart';
// Import web implementation which is either the stub or the real one

/// Factory method to get the storage implementation based on platform
StorageInterface getStorageImplementation() {
  if (kIsWeb) {
    // Web platform
    return StorageImplementationWeb();
  } else {
    // Non-web platform (iOS, Android, desktop)
    return StorageImplementationIO();
  }
}