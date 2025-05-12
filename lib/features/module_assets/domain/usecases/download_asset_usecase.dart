import 'dart:convert';
import 'dart:typed_data';
import 'package:assets_differ/core/logging.dart';
import 'package:assets_differ/core/utils/performance_tracker.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/save_uint8list_image_usecase.dart';
import 'package:assets_differ/core/logging.dart';

/// UseCase for downloading and saving a single asset
class DownloadAssetUseCase {
  final DummyDataRepository _repository;
  late final SaveUint8ListImageUseCase _saveUint8ListImageUseCase;
  final _logger = AssetLogger('DownloadAssetUseCase');

  /// Constructor with dependency injection
  DownloadAssetUseCase({
    required SaveUint8ListImageUseCase saveUint8ListImageUseCase,
    required DummyDataRepository repository,
  })  : _saveUint8ListImageUseCase = saveUint8ListImageUseCase,
        _repository = repository;

  /// Download and save a single asset based on its type
  Future<ImageUploadResponse> execute(AssetItem asset) async {
    PerformanceTracker.startTracking('DownloadAssetUseCase.execute');

    try {
      _logger.debug('Downloading asset: ${asset.path}');

      // Download the image data as bytes
      PerformanceTracker.startTracking('RemoteDataSource.loadImageFromUrl');
      final Uint8List imageBytes =
          await _repository.loadImageFromUrl(asset.url);
      PerformanceTracker.endTracking('RemoteDataSource.loadImageFromUrl');

      // Delegate saving to the specialized use case
      final format = _getImageFormat(asset.path);
      final response = await _saveUint8ListImageUseCase.execute(
        assetPath: asset.path,
        imageBytes: imageBytes,
        format: format,
      );

      if (response.isSuccess) {
        _logger.debug(
            'Successfully saved asset: ${asset.path} (${response.imageBytesLength} bytes)');
      } else {
        _logger.error('Failed to save asset ${asset.path}',
            'Save operation failed', StackTrace.current);
      }

      return response;
    } catch (e, stackTrace) {
      _logger.error('Failed to download asset: ${asset.path}', e, stackTrace);
      return ImageUploadResponse(
        imageBytesLength: 0,
        isSuccess: false,
      );
    } finally {
      PerformanceTracker.endTracking('DownloadAssetUseCase.execute');
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
}
