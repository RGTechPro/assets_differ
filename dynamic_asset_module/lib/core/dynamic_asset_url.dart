/// A data class that represents a dynamic asset URL with the format:
/// `dynamic-assets://${asset.path}?version=${manifest.version}`
class DynamicAssetUrl {
  /// The protocol/scheme used for dynamic assets (dynamic-assets://)
  static const String protocol = 'dynamic-assets';

  /// The path component of the URL (e.g., 'assets/logo.png')
  final String path;

  /// The version of the asset from the manifest
  final String? version;

  /// Any additional parameters included in the URL
  final Map<String, String> extraParams;

  /// Creates a [DynamicAssetUrl] with the given path, version, and optional extra parameters.
  const DynamicAssetUrl({
    required this.path,
    this.version,
    this.extraParams = const {},
  });

  /// Parses a URL string in the format `dynamic-assets://${path}?version=${version}`
  /// and returns a [DynamicAssetUrl] instance.
  factory DynamicAssetUrl.parse(String url) {
    final uri = Uri.parse(url);

    // Validate scheme
    if (uri.scheme != protocol) {
      throw FormatException(
          'Invalid dynamic asset URL scheme: ${uri.scheme}. Expected: $protocol');
    }

    // Extract version from query parameters
    final version = uri.queryParameters['version'];


    // Remove version from query parameters to get extra params
    final extraParams = Map<String, String>.from(uri.queryParameters);
    extraParams.remove('version');

    return DynamicAssetUrl(
      path: uri.host + uri.path, // Combine host and path parts
      version: version,
      extraParams: extraParams,
    );
  }

  /// Attempts to parse a URL string and returns null if parsing fails
  /// instead of throwing an exception.
  static DynamicAssetUrl? tryParse(String url) {
    try {
      return DynamicAssetUrl.parse(url);
    } catch (e) {
      return null;
    }
  }

  /// Converts the [DynamicAssetUrl] back to a string URL.
  String toUrl() {
    final queryParams = <String, String>{
      if (version != null) 'version': version!,
      ...extraParams,
    };

    final queryString = queryParams.entries
        .map((e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$protocol://$path?$queryString';
  }

  /// Creates a new [DynamicAssetUrl] with some properties replaced.
  DynamicAssetUrl copyWith({
    String? path,
    String? version,
    Map<String, String>? extraParams,
  }) {
    return DynamicAssetUrl(
      path: path ?? this.path,
      version: version ?? this.version,
      extraParams: extraParams ?? this.extraParams,
    );
  }

  @override
  String toString() => toUrl();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DynamicAssetUrl &&
        other.path == path &&
        other.version == version &&
        _mapsEqual(other.extraParams, extraParams);
  }

  @override
  int get hashCode => Object.hash(
    path,
    version,
    Object.hashAllUnordered(extraParams.entries),
  );

  // Helper method to compare maps
  bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    return a.entries.every((e) => b[e.key] == e.value);
  }
}

const DynamicAssetUrl kZeroPixel = DynamicAssetUrl(
  path: 'assets/zero_pixel.png',
  version: '',
);