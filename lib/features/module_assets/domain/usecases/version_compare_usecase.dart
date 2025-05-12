import 'package:assets_differ/core/logging.dart';

/// Enum representing different types of version changes
enum VersionChange {
  none,   // No change
  patch,  // Only patch version changed (x.y.Z)
  minor,  // Minor version changed (x.Y.z)
  major,  // Major version changed (X.y.z)
}

/// UseCase to compare semantic versions and determine the type of change
class VersionCompareUseCase {
  final _logger = AssetLogger('VersionCompareUseCase');

  final String currentVersion;

  VersionCompareUseCase(this.currentVersion);

  /// Determine the type of version change between two semantic versions
  VersionChange compareVersions(String oldVersion) {
    final List<int> oldParts = _parseSemanticVersion(oldVersion);
    final List<int> newParts = _parseSemanticVersion(currentVersion);
    
    if (oldParts[0] != newParts[0]) {
      return VersionChange.major;
    } else if (oldParts[1] != newParts[1]) {
      return VersionChange.minor;
    } else if (oldParts[2] != newParts[2]) {
      return VersionChange.patch;
    }
    
    return VersionChange.none;
  }
  
  /// Parse a semantic version string into its numeric components
  List<int> _parseSemanticVersion(String version) {
    final parts = version.split('.');
    final result = <int>[0, 0, 0]; // Default to [0,0,0]
    
    try {
      for (int i = 0; i < parts.length && i < 3; i++) {
        result[i] = int.parse(parts[i]);
      }
    } catch (e) {
      _logger.error('Error parsing version: $version', e);
    }
    
    return result;
  }
}
