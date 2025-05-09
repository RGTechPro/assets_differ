// IO-specific implementation that imports the actual Flutter services
import 'package:flutter/services.dart';

// Re-export the RootIsolateToken class
export 'package:flutter/services.dart' show RootIsolateToken;

// Function to initialize the binary messenger
void initializeBackgroundIsolateBinaryMessenger(dynamic token) {
  if (token is RootIsolateToken) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  }
}