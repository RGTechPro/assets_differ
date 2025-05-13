// Web-specific stub implementation - avoids importing Flutter services on web

// Stub implementation of RootIsolateToken
class RootIsolateToken {
  // Always returns null on web platform
  static RootIsolateToken? get instance => null;
}

// No-op function for web platform
void initializeBackgroundIsolateBinaryMessenger(dynamic token) {
  // Does nothing on web
}