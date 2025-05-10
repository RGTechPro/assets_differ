import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:assets_differ/core/utils/performance_tracker.dart';
import 'package:assets_differ/features/module_assets/data/models/asset_manifest.dart';
import 'package:assets_differ/features/module_assets/data/dummy_data_repository.dart';
import 'package:flutter/services.dart';
import 'package:assets_differ/core/logging.dart';

/// UseCase for saving Uint8List image data to local storage
class SaveUint8ListImageUseCase {
  final DummyDataRepository _repository;
  final _logger = AssetLogger('SaveUint8ListImageUseCase');

  /// Constructor with dependency injection
  SaveUint8ListImageUseCase(this._repository);

  /// Save a Uint8List image to local storage with the given path
  /// 
  /// Parameters:
  /// - [assetPath]: The path to save the image to
  /// - [imageBytes]: The raw image bytes as Uint8List
  /// - [format]: The image format (default: 'png')
  /// 
  /// Returns an [ImageUploadResponse] with information about the operation
  Future<ImageUploadResponse> execute({
    required String assetPath, 
    required Uint8List imageBytes,
    String format = 'png',
  }) async {
    PerformanceTracker.startTracking('SaveUint8ListImageUseCase.execute');
    
    try {
      _logger.debug('Saving image to path: $assetPath (${imageBytes.length} bytes)');
      
      // Convert bytes to base64 string for storage
      PerformanceTracker.startTracking('Base64Encode');
      final String base64Image = base64Encode(imageBytes);
      PerformanceTracker.endTracking('Base64Encode');
      
      // Add data URI prefix for proper handling
      final String dataUri = 'data:image/$format;base64,$base64Image';
      
      // Save the image data to local storage
      await _repository.saveAssetByPath(assetPath, dataUri);
      
      _logger.debug('Successfully saved image: $assetPath (${imageBytes.length} bytes)');
      
      return ImageUploadResponse(
        imageBytesLength: imageBytes.length,
        isSuccess: true,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to save image: $assetPath', e, stackTrace);
      return ImageUploadResponse(
        imageBytesLength: 0,
        isSuccess: false,
      );
    } finally {
      PerformanceTracker.endTracking('SaveUint8ListImageUseCase.execute');
    }
  }
  
  /// Save an image from a base64 string to local storage
  Future<ImageUploadResponse> executeFromBase64({
    required String assetPath, 
    required String base64String,
    String format = 'png',
  }) async {
    PerformanceTracker.startTracking('SaveUint8ListImageUseCase.executeFromBase64');
    
    try {
      _logger.debug('Saving base64 image to path: $assetPath');
      
      // Extract base64 data if it's a data URI
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',')[1];
      }
      
      // Decode base64 to bytes
      final Uint8List imageBytes = base64Decode(cleanBase64);
      
      // Use the main execute method
      final result = await execute(
        assetPath: assetPath,
        imageBytes: imageBytes,
        format: format,
      );
      
      return result;
    } catch (e, stackTrace) {
      _logger.error('Failed to process base64 string for $assetPath', e, stackTrace);
      return ImageUploadResponse(
        imageBytesLength: 0,
        isSuccess: false,
      );
    } finally {
      PerformanceTracker.endTracking('SaveUint8ListImageUseCase.executeFromBase64');
    }
  }
  
  /// Save an image from a ui.Image to local storage
  /// 
  /// This is useful when working with canvases or other drawing operations
  Future<ImageUploadResponse> executeFromUiImage({
    required String assetPath, 
    required ui.Image image,
    String format = 'png',
  }) async {
    PerformanceTracker.startTracking('SaveUint8ListImageUseCase.executeFromUiImage');
    
    try {
      _logger.debug('Converting ui.Image to bytes for path: $assetPath');
      
      // Convert ui.Image to ByteData
      final ByteData? byteData = await image.toByteData(
        format: format == 'png' ? ui.ImageByteFormat.png : ui.ImageByteFormat.rawRgba
      );
      
      if (byteData == null) {
        throw Exception('Failed to convert ui.Image to ByteData');
      }
      
      // Convert ByteData to Uint8List
      final Uint8List bytes = byteData.buffer.asUint8List();
      
      // Use the main execute method
      final result = await execute(
        assetPath: assetPath,
        imageBytes: bytes,
        format: format,
      );
      
      return result;
    } catch (e, stackTrace) {
      _logger.error('Failed to save ui.Image for $assetPath', e, stackTrace);
      return ImageUploadResponse(
        imageBytesLength: 0,
        isSuccess: false,
      );
    } finally {
      PerformanceTracker.endTracking('SaveUint8ListImageUseCase.executeFromUiImage');
    }
  }
  
  /// Generate and save a transparent 1x1 pixel image
  Future<ImageUploadResponse> generateAndSaveTransparentPixel(String assetPath) async {
    PerformanceTracker.startTracking('SaveUint8ListImageUseCase.generateTransparentPixel');
    
    try {
      _logger.debug('Generating transparent pixel image for path: $assetPath');
      
      // Create a 1x1 transparent image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, 1, 1));
      final ui.Paint paint = ui.Paint()..color = const ui.Color(0x00000000); // Fully transparent
      canvas.drawRect(ui.Rect.fromLTWH(0, 0, 1, 1), paint);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(1, 1);
      final ByteData? pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (pngData == null) {
        throw Exception('Failed to generate transparent pixel image - ByteData is null');
      }
      
      // Convert to Uint8List and save using the main execute method
      final Uint8List imageBytes = pngData.buffer.asUint8List();
      
      final result = await execute(
        assetPath: assetPath,
        imageBytes: imageBytes,
        format: 'png',
      );
      
      _logger.debug('Generated and saved transparent pixel image to $assetPath');
      
      // Dispose of the image to prevent memory leaks
      image.dispose();
      
      return result;
    } catch (e, stackTrace) {
      _logger.error('Error generating transparent pixel image', e, stackTrace);
      return ImageUploadResponse(
        imageBytesLength: 0,
        isSuccess: false,
      );
    } finally {
      PerformanceTracker.endTracking('SaveUint8ListImageUseCase.generateTransparentPixel');
    }
  }
}