import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:assets_differ/core/utils/performance_tracker.dart';
import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:assets_differ/features/module_assets/domain/usecases/save_uint8list_image_usecase.dart';
import 'package:assets_differ/features/module_assets/presentation/controllers/assets_controller.dart';
import 'package:assets_differ/core/logging.dart';

/// UseCase for ensuring that the zero pixel placeholder image exists
/// This is used as a fallback when actual images aren't available
class EnsureZeroPixelImageExistsUseCase {
  final DummyDataRepository _repository;
  final SaveUint8ListImageUseCase _saveUint8ListImageUseCase;
  final _logger = AssetLogger('EnsureZeroPixelImageExistsUseCase');

  final zeroPixelPath = kZeroPixel.path;

  /// Constructor with dependency injection
  EnsureZeroPixelImageExistsUseCase({
    required DummyDataRepository repository,
    required SaveUint8ListImageUseCase saveUint8ListImageUseCase,
  }) : _repository = repository,
       _saveUint8ListImageUseCase = saveUint8ListImageUseCase;

  /// Execute the use case to ensure a zero pixel image exists
  /// If it doesn't exist, it will be created
  /// 
  /// Returns true if the image already existed or was successfully created
  Future<bool> execute() async {
    PerformanceTracker.startTracking('EnsureZeroPixelImageExistsUseCase.execute');
    
    try {
      
      // First check if the zero pixel image already exists
      try {
        
        final Uint8List? zeroAssetPath = await _repository.getAssetByPath(zeroPixelPath);
        if (zeroAssetPath != null) {
          _logger.info('Zero pixel image already exists');
          PerformanceTracker.endTracking('EnsureZeroPixelImageExistsUseCase.execute');
          return true;
        }
      } catch (e) {
        // Image doesn't exist - we'll create it
        _logger.info('Zero pixel image not found - will generate');
      }

      // Create a 1x1 transparent image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 1, 1));
      final ui.Paint paint = ui.Paint()..color = const ui.Color(0x00000000); // Fully transparent
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), paint);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(1, 1);
      final ByteData? pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (pngData != null) {
        // Convert to base64 encoded string
        final String base64Image = 'data:image/png;base64,${base64Encode(pngData.buffer.asUint8List())}';
        
        // Save to repository
        final result = await _saveUint8ListImageUseCase.executeFromBase64(
          assetPath: zeroPixelPath, 
          base64String: base64Image
        );
        
        // Cleanup resources
        image.dispose();
        
        _logger.info('Generated and saved zero pixel image - success: ${result.isSuccess}');
        PerformanceTracker.endTracking('EnsureZeroPixelImageExistsUseCase.execute');
        return result.isSuccess;
      } else {
        _logger.error('Failed to generate zero pixel image - ByteData is null');
        PerformanceTracker.endTracking('EnsureZeroPixelImageExistsUseCase.execute');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.error('Error generating zero pixel image', e, stackTrace);
      PerformanceTracker.endTracking('EnsureZeroPixelImageExistsUseCase.execute');
      return false;
    }
  }
  
  /// Alternative implementation that uses the SaveUint8ListImageUseCase's built-in method
  /// This approach delegates the image generation to the SaveUint8ListImageUseCase
  Future<bool> executeUsingHelper() async {
    PerformanceTracker.startTracking('EnsureZeroPixelImageExistsUseCase.executeUsingHelper');
    
    try {
      // First check if the zero pixel image already exists
      try {
        final Uint8List? zeroAssetPath = await _repository.getAssetByPath(zeroPixelPath);
        if (zeroAssetPath != null) {
          _logger.info('Zero pixel image already exists');
          PerformanceTracker.endTracking('EnsureZeroPixelImageExistsUseCase.executeUsingHelper');
          return true;
        }
      } catch (e) {
        // Image doesn't exist - we'll create it
        _logger.info('Zero pixel image not found - will generate');
      }

      // Use the dedicated method in SaveUint8ListImageUseCase
      final result = await _saveUint8ListImageUseCase.generateAndSaveTransparentPixel(zeroPixelPath);
      
      _logger.info('Generated and saved zero pixel image using helper - success: ${result.isSuccess}');
      PerformanceTracker.endTracking('EnsureZeroPixelImageExistsUseCase.executeUsingHelper');
      return result.isSuccess;
    } catch (e, stackTrace) {
      _logger.error('Error generating zero pixel image using helper', e, stackTrace);
      PerformanceTracker.endTracking('EnsureZeroPixelImageExistsUseCase.executeUsingHelper');
      return false;
    }
  }
}