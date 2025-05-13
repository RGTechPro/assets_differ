import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:assets_differ/core/utils/performance_tracker.dart';
import 'package:assets_differ/core/logging.dart';

class ZeroPixelImageDataGeneratorUsecase {
  final _logger = AssetLogger('EnsureZeroPixelImageExistsUseCase');

  Future<Uint8List> execute() async {
    PerformanceTracker.startTracking(
        'EnsureZeroPixelImageExistsUseCase.execute');

    try {
      // First check if the zero pixel image already exists

      // Create a 1x1 transparent image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas =
          ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 1, 1));
      final ui.Paint paint = ui.Paint()
        ..color = const ui.Color(0x00000000); // Fully transparent
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), paint);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(1, 1);
      final ByteData? pngData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (pngData != null) {
        // Convert to base64 encoded string

        return pngData.buffer.asUint8List();
      }

      throw Exception('Failed to generate zero pixel image - ByteData is null');

      // Cleanup resources
    } catch (e, stackTrace) {
      _logger.error('Error generating zero pixel image', e, stackTrace);
      PerformanceTracker.endTracking(
          'EnsureZeroPixelImageExistsUseCase.execute');
      rethrow;
    }
  }
}
