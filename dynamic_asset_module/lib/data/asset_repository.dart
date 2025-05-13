// import 'dart:io';
// import 'package:assets_differ/core/config/asset_config.dart';
// import 'package:assets_differ/core/models/asset_models.dart';
// import 'package:assets_differ/core/services/asset_service.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// /// Repository for fetching and managing assets
// class AssetRepository {
//   final AssetService _assetService;
//
//   AssetRepository(this._assetService);
//
//   // /// Simulate fetching and applying updates for a module
//   // ///
//   // /// In a real implementation, this would call the backend API
//   // Future<bool> simulateUpdateCheck(String moduleName) async {
//   //   // Simulate network delay
//   //   await Future.delayed(const Duration(seconds: 1));
//   //
//   //   // Create a dummy response based on the module name
//   //   final moduleAssets = AssetConfig.demoAssetsTest[moduleName] ?? [];
//   //
//   //   if (moduleAssets.isEmpty) {
//   //     return false;
//   //   }
//   //
//   //   // Create a simulated asset update response
//   //   final assetsList = moduleAssets.map((assetPath) {
//   //     return CdnAsset(
//   //       path: '$moduleName/$assetPath',
//   //       hash: '${DateTime.now().millisecondsSinceEpoch}',
//   //       url: 'https://picsum.photos/${Uri.encodeComponent(assetPath)}/300/300',
//   //       priority: moduleAssets.indexOf(assetPath),
//   //     );
//   //   }).toList();
//   //
//   //   // Download all assets
//   //   await _assetService.downloadAssets(assetsList);
//   //
//   //   // Save version information
//   //   await _simulateSaveVersion(moduleName);
//   //
//   //   return true;
//   // }
//   //
//   /// Simulate saving version information
//   // Future<void> _simulateSaveVersion(String moduleName) async {
//   //   try {
//   //     final directory = Directory('${(await _assetService).getAssetPath(moduleName)}');
//   //     if (!await directory.exists()) {
//   //       await directory.create(recursive: true);
//   //     }
//   //
//   //     final file = File('${(await _assetService).getAssetPath('$moduleName/version.json')}');
//   //     await file.writeAsString(jsonEncode({
//   //       'version': AssetConfig.appVersion,
//   //       'timestamp': DateTime.now().toIso8601String(),
//   //     }));
//   //   } catch (e) {
//   //     print('Error saving version: $e');
//   //   }
//   // }
//
//   /// Get a list of downloaded assets for a module
//   Future<List<String>> getDownloadedAssets(String moduleName) async {
//     try {
//       final directory = Directory('${(await _assetService).getAssetPath(moduleName)}');
//       if (!await directory.exists()) {
//         return [];
//       }
//
//       final List<String> assets = [];
//       await for (final entity in directory.list(recursive: true)) {
//         if (entity is File &&
//             !entity.path.endsWith('version.json') &&
//             !entity.path.contains('.DS_Store')) {
//           final String relativePath = entity.path.split('$moduleName/').last;
//           assets.add(relativePath);
//         }
//       }
//
//       return assets;
//     } catch (e) {
//       print('Error listing assets: $e');
//       return [];
//     }
//   }
// }