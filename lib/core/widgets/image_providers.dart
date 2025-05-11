import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../services/file_storage_service.dart';

class AssetInfo {
  final String assetPath;
  final String? cacheVersion;

  AssetInfo(this.assetPath, this.cacheVersion);

  @override
  int get hashCode => Object.hash(assetPath, cacheVersion);
  @override
  String toString() => 'AssetInfo($assetPath, $cacheVersion)';
  @override
  bool operator ==(Object other) {
    if (other is AssetInfo) {
      return assetPath == other.assetPath && cacheVersion == other.cacheVersion;
    }
    return false;
  }
}

/// Image provider that loads images directly from FileStorageService.
/// This works with asset paths stored in the app's local storage system.
class FileAssetImageProvider extends ImageProvider<FileAssetImageProvider> {
  /// Creates an object that fetches the image from FileStorageService.
  ///
  /// The [assetPath] argument must not be null.
  FileAssetImageProvider(
    String assetPath, {
    this.scale = 1.0,
  }) : assetInfo = _getAssetInfo(assetPath);

  static AssetInfo _getAssetInfo(String assetInfo) {
    final assetData = assetInfo.split(";");
    return AssetInfo(
      assetData.first,
      assetData.length > 1 ? assetData.last : null,
    );
  }

  /// The path to the asset in the local storage system.
  final AssetInfo assetInfo;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  @override
  Future<FileAssetImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FileAssetImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    FileAssetImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: 'FileAssetImageProvider(${key.assetInfo}, scale: $scale)',
    );
  }

  Future<ui.Codec> _loadAsync(
      FileAssetImageProvider key, ImageDecoderCallback decode) async {
    try {
      final assetPath = key.assetInfo.assetPath;

      // Directly use FileStorageService to get the asset
      final String data =
          await FileStorageService.instance.getAssetByPath(assetPath);

      if (data.isEmpty) {
        throw StateError('Asset not found: ${key.assetInfo.assetPath}');
      }

      // Extract base64 data if it's a data URI
      String base64Data = data;
      if (data.contains(',')) {
        base64Data = data.split(',')[1];
      }

      // Decode base64 to bytes
      final Uint8List bytes = base64Decode(base64Data);

      // Create an ImmutableBuffer from the bytes and decode with the provided callback
      final ui.ImmutableBuffer buffer =
          await ui.ImmutableBuffer.fromUint8List(bytes);
      final ui.Codec codec = await decode(buffer);

      return codec;
    } catch (e) {
      throw StateError(
          'Failed to load image from asset path ${key.assetInfo.assetPath}: $e');
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is FileAssetImageProvider &&
        other.assetInfo == assetInfo &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(assetInfo, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'FileAssetImageProvider')}($assetInfo, scale: $scale)';
}

//TODO: TO[@shashank] - [Base64ImageProvider] may not be needed in the future
/// Image provider that loads images from base64 encoded strings.
/// This can handle both raw base64 strings and data URIs (e.g., 'data:image/png;base64,...').
class Base64ImageProvider extends ImageProvider<Base64ImageProvider> {
  /// Creates an object that decodes a base64 string as an image.
  ///
  /// The [base64String] argument must not be null.
  const Base64ImageProvider(
    this.base64String, {
    this.scale = 1.0,
  });

  /// The base64 encoded string to decode into an image.
  final String base64String;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  @override
  Future<Base64ImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<Base64ImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      Base64ImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: 'Base64ImageProvider',
    );
  }

  Future<ui.Codec> _loadAsync(
      Base64ImageProvider key, ImageDecoderCallback decode) async {
    try {
      // Extract base64 string from the data URI if present
      String base64Data = key.base64String;
      if (base64Data.contains(',')) {
        base64Data = base64Data.split(',')[1];
      }

      // Decode base64 to bytes
      final Uint8List bytes = base64Decode(base64Data);

      // Create an ImmutableBuffer from the bytes and decode with the provided callback
      final ui.ImmutableBuffer buffer =
          await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } catch (e) {
      // If there's any error in decoding, rethrow with more details
      throw StateError('Failed to load image from base64 data: $e');
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is Base64ImageProvider &&
        other.base64String == base64String &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(base64String, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'Base64ImageProvider')}($base64String, scale: $scale)';
}
