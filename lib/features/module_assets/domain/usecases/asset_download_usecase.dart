import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';

import 'package:assets_differ/core/logging.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/save_uint8list_image_usecase.dart';
import 'package:flutter/foundation.dart';

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
  /// Downloads P1 and P2 assets and updates the manifest
  Future<void> processBackgroundAssets({
    List<AssetItem> p0Assets = const [],
    required List<AssetItem> p1Assets,
    required List<AssetItem> p2Assets,
    required AssetManifest remoteManifest,
  }) async {
    try {
      // Process P0, P1 and P2 assets in order
      await saveAssetsToLocalStorage(p0Assets);
      await saveAssetsToLocalStorage(p1Assets);
      await saveAssetsToLocalStorage(p2Assets);

      // Save the updated manifest to local storage
      await _repository.setLocalManifest(remoteManifest);

      _logger.info('Background asset processing complete');
    } catch (e, stackTrace) {
      _logger.error('Error in background asset processing', e, stackTrace);
    }
  }
}
