import 'package:dynamic_asset_module/core/dynamic_asset_url.dart';
import 'package:flutter/cupertino.dart';

abstract class AssetMapper<T> {
  @protected
  String defaultAssetPath = kZeroPixel.path;
  void updateFromAssetMap(T assets, Map<String, String> json);
  T empty();
}