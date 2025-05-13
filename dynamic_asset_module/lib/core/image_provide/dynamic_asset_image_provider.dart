import 'dart:convert';

import 'package:dynamic_asset_module/core/dynamic_asset_url.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'dart:async';
import 'dart:ui' as ui;
import 'package:dynamic_asset_module/core/services/file_storage_service.dart';

/// Image provider that loads images directly from FileStorageService.
/// This works with asset paths stored in the app's local storage system.
class DynamicAssetImageProvider extends ImageProvider<DynamicAssetImageProvider> {
  /// Creates an object that fetches the image from FileStorageService.
  ///
  /// The [assetPath] argument must not be null.
  DynamicAssetImageProvider(
    String assetPath, {
    this.scale = 1.0,
  }) : assetInfo = DynamicAssetUrl.parse(assetPath);

  /// The path to the asset in the local storage system.
  final DynamicAssetUrl assetInfo;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  @override
  Future<DynamicAssetImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<DynamicAssetImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    DynamicAssetImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: 'FileAssetImageProvider(${key.assetInfo}, scale: $scale)',
    );
  }

  Future<ui.Codec> _loadAsync(
    DynamicAssetImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final assetPath = key.assetInfo.path;

      // Directly use FileStorageService to get the asset
      final String data =
          await FileStorageService.instance.getAssetByPath(assetPath);

      if (data.isEmpty) {
        throw StateError('Asset not found: ${key.assetInfo.path}');
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
          'Failed to load image from asset path ${key.assetInfo.path}: $e');
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is DynamicAssetImageProvider &&
        other.assetInfo == assetInfo &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(assetInfo, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'FileAssetImageProvider')}($assetInfo, scale: $scale)';
}
