// lib/src/core/utils/file_utils.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants.dart';

/// Utilidad para operaciones con archivos
class FileUtils {
  
  /// Copia un archivo de video a la carpeta de la aplicación
  static Future<String> copyVideoFile(String originalPath) async {
    final docDir = await getApplicationDocumentsDirectory();
    final videosDir = Directory(
      p.join(docDir.path, AppConstants.videosSubdirectory)
    );

    // Crear directorio si no existe
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }

    // Generar nombre único con timestamp
    final fileExtension = p.extension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final uniqueFileName = 'video_$timestamp$fileExtension';
    final destinationPath = p.join(videosDir.path, uniqueFileName);

    // Copiar archivo
    await File(originalPath).copy(destinationPath);

    return destinationPath;
  }

  /// Elimina un archivo de manera segura
  static Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error eliminando archivo $path: $e');
      rethrow;
    }
  }

  /// Verifica si un archivo existe
  static Future<bool> fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el tamaño de un archivo en bytes
  static Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }
}