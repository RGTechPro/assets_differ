import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:flutter/foundation.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'dart:convert';
import 'package:assets_differ/core/logging.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/save_uint8list_image_usecase.dart';
import 'package:flutter/foundation.dart';

// Correctly handle conditional imports for different platforms
import 'services_io.dart' if (dart.library.html) 'services_web.dart'
    as services;

// Top-level function for isolate_manager

/// UseCase for downloading and saving assets
class AssetDownloadUseCase {
  final DummyDataRepository _repository;
  final _logger = AssetLogger('AssetDownloadUseCase');
  final SaveUint8ListImageUseCase _saveUint8ListImageUseCase;

  AssetDownloadUseCase({
    required SaveUint8ListImageUseCase saveUint8ListImageUseCase,
    required DummyDataRepository repository,
  })  : _repository = repository,
        _saveUint8ListImageUseCase = saveUint8ListImageUseCase;

  @pragma('vm:entry-point')
  Future<void> isolateSaveAssets(Map<String, dynamic> params) async {
    // Extract the rootIsolateToken and assetListMap from the params
    final rootIsolateToken = params['rootIsolateToken'];
    final assetListMap =
        List<Map<String, dynamic>>.from(params['assetListMap']);

    // Initialize with the token
    if (!kIsWeb) {
      services.initializeBackgroundIsolateBinaryMessenger(rootIsolateToken);
    }
    final assetList =
        assetListMap.map((map) => AssetItem.fromJson(map)).toList();
    if (assetList.isEmpty) return;

    final logger = AssetLogger('IsolateSaveAssets');

    logger.info('Isolate: Saving ${assetList.length} assets to local storage');

    // Process each asset in parallel for efficiency
    await Future.wait(
      assetList.map((asset) async {
        try {
          logger.debug('Isolate: Downloading image: ${asset.url}');
          await _downloadAndSaveAsset(asset);
        } catch (e, stackTrace) {
          logger.error(
              'Isolate: Failed to process asset ${asset.path}', e, stackTrace);
        }
      }),
    );
  }

  /// Save assets to local storage
  Future<void> saveAssetsToLocalStorage(List<AssetItem> assetList) async {
    if (assetList.isEmpty) return;

    _logger.info('Saving ${assetList.length} assets to local storage');

    // Process each asset in parallel for efficiency
    await Future.wait(
      assetList.map((asset) => _downloadAndSaveAsset(asset)),
    );
  }

  /// Download and save a single asset based on its type
  Future<void> _downloadAndSaveAsset(AssetItem asset) async {
    try {
      _logger.debug('Downloading image: ${asset.url}');

      final Uint8List imageBytes =
          await _repository.loadImageFromUrl(asset.url);

      // Delegate saving to the specialized use case
      final format = _getImageFormat(asset.path);
      final response = await _saveUint8ListImageUseCase.execute(
        assetPath: asset.path,
        imageBytes: imageBytes,
        format: format,
      );

      _logger.debug(
          'Saved image: ${asset.path} (${response.imageBytesLength} bytes)');
    } catch (e, stackTrace) {
      _logger.error('Failed to process asset ${asset.path}', e, stackTrace);
    }
  }

  /// Determine image format from file extension
  String _getImageFormat(String path) {
    final String ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      case 'bmp':
        return 'bmp';
      default:
        return 'png'; // default format
    }
  }

  /// Process prioritized assets in background
  /// Downloads P0, P1, and P2 assets in parallel using isolates and updates the manifest
  Future<void> processBackgroundAssets({
    List<AssetItem> p0Assets = const [],
    required List<AssetItem> p1Assets,
    required List<AssetItem> p2Assets,
    required AssetManifest remoteManifest,
  }) async {
    try {
      _logger.info('Starting parallel asset processing with isolate_manager');

      // Get a token from the root isolate to pass to background isolates
      final token = services.RootIsolateToken.instance;

      // Check if token is available (it will be null on web)
      if (token == null || kIsWeb) {
        // Fall back to sequential processing if token is not available on non-web platforms
        _logger.info('Isolate token unavailable, using sequential processing');
        await saveAssetsToLocalStorage(p0Assets);
        await saveAssetsToLocalStorage(p1Assets);
        await saveAssetsToLocalStorage(p2Assets);
        await _repository.setLocalManifest(remoteManifest);
        _logger.info('Sequential asset processing complete');
        return;
      }

      // Create three separate isolate manager instances for concurrent processing
      final p0IsolateManager = IsolateManager.create(
        isolateSaveAssets,
        concurrent: 1, // Use one isolate for this asset list
        workerName: 'worker',
      );

      final p1IsolateManager = IsolateManager.create(
        isolateSaveAssets,
        concurrent: 1,
        workerName: 'worker',
      );

      final p2IsolateManager = IsolateManager.create(
        isolateSaveAssets,
        concurrent: 1,
        workerName: 'worker',
      );

      // Start all isolate managers simultaneously
      await Future.wait([
        p0IsolateManager.start(),
        p1IsolateManager.start(),
        p2IsolateManager.start(),
      ]);

      // Prepare parameters for each isolate
      Map<String, dynamic> p0Params = {
        'assetListMap': p0Assets.map((asset) => asset.toJson()).toList()
      };
      Map<String, dynamic> p1Params = {
        'assetListMap': p1Assets.map((asset) => asset.toJson()).toList()
      };
      Map<String, dynamic> p2Params = {
        'assetListMap': p2Assets.map((asset) => asset.toJson()).toList()
      };

      // Only add the token for non-web platforms
      if (!kIsWeb && token != null) {
        p0Params['rootIsolateToken'] = token;
        p1Params['rootIsolateToken'] = token;
        p2Params['rootIsolateToken'] = token;
      }

      // Process all asset lists in parallel using different isolates
      await Future.wait([
        p0IsolateManager.compute(p0Params),
        p1IsolateManager.compute(p1Params),
        p2IsolateManager.compute(p2Params),
      ]);

      // Stop all isolate managers when done
      await Future.wait([
        p0IsolateManager.stop(),
        p1IsolateManager.stop(),
        p2IsolateManager.stop(),
      ]);

      // Save the updated manifest to local storage
      await _repository.setLocalManifest(remoteManifest);

      _logger.info('Background asset processing complete (all isolates)');
    } catch (e, stackTrace) {
      _logger.error('Error in background asset processing', e, stackTrace);
    }
  }
}
