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
}