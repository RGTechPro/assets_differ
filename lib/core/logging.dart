import 'package:flutter/foundation.dart';

/// Simple logger class for asset operations
class AssetLogger {
  final String _tag;

  AssetLogger(this._tag);

  void debug(String message) {
    if (kDebugMode) print('[$_tag] DEBUG: $message');
  }

  void info(String message) {
    print('[$_tag] INFO: $message');
  }

  void warn(String message) {
    print('[$_tag] WARN: $message');
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    print('[$_tag] ERROR: $message${error != null ? ' - $error' : ''}');
    if (kDebugMode && stackTrace != null) {
      print('[$_tag] STACK: $stackTrace');
    }
  }
}