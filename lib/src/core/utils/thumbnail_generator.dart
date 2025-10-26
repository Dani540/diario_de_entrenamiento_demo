// lib/src/core/utils/thumbnail_generator.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../constants.dart';

/// Utilidad para generar thumbnails de videos
class ThumbnailGenerator {
  
  /// Genera un thumbnail para un video (solo en móvil)
  static Future<String?> generate(String videoPath) async {
    // Solo genera thumbnails en plataformas móviles
    if (!Platform.isAndroid && !Platform.isIOS) {
      return null;
    }

    try {
      final supportDir = await getApplicationSupportDirectory();
      final thumbDir = Directory(
        p.join(supportDir.path, AppConstants.thumbnailsSubdirectory)
      );

      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: AppConstants.thumbnailMaxWidth,
        quality: AppConstants.thumbnailQuality,
      );

      return thumbnailPath;
    } catch (e) {
      print('Error generando thumbnail: $e');
      return null;
    }
  }

  /// Regenera un thumbnail existente
  static Future<String?> regenerate(String videoPath, String? oldThumbnailPath) async {
    // Eliminar thumbnail antiguo si existe
    if (oldThumbnailPath != null) {
      try {
        final oldFile = File(oldThumbnailPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (e) {
        print('Error eliminando thumbnail antiguo: $e');
      }
    }

    // Generar nuevo thumbnail
    return await generate(videoPath);
  }
}