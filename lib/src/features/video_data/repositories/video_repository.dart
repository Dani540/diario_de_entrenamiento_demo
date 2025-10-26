// lib/src/features/video_data/repositories/video_repository.dart
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/video_entry.dart';
import '../../../core/constants.dart';

/// Repositorio para gestionar las operaciones CRUD de videos
/// Encapsula toda la lógica de acceso a datos
class VideoRepository {
  late final Box<VideoEntry> _box;

  VideoRepository(this._box);

  // Factory para obtener instancia con la caja de Hive
  static Future<VideoRepository> initialize() async {
    final box = await Hive.openBox<VideoEntry>(AppConstants.videoEntriesBoxName);
    return VideoRepository(box);
  }

  /// Obtiene todos los videos NO archivados
  List<VideoEntry> getActiveVideos() {
    return _box.values.where((entry) => !entry.isArchived).toList();
  }

  /// Obtiene todos los videos (incluyendo archivados)
  List<VideoEntry> getAllVideos() {
    return _box.values.toList();
  }

  /// Obtiene todos los tags de videos activos o todos según configuración
  List<String> getAllTags({bool includeArchived = false}) {
    final videos = includeArchived ? getAllVideos() : getActiveVideos();
    final Set<String> allTags = {};
    
    for (var entry in videos) {
      allTags.addAll(entry.tags);
    }
    
    return allTags.toList();
  }

  /// Busca un video por su path
  VideoEntry? getVideoByPath(String videoPath) {
    try {
      return _box.values.firstWhere(
        (entry) => entry.videoPath == videoPath,
      );
    } catch (e) {
      return null;
    }
  }

  /// Verifica si un video ya existe (por nombre de archivo o path completo)
  bool videoExists(String originalVideoPath) {
    return _box.values.any((entry) =>
        p.basename(entry.videoPath) == p.basename(originalVideoPath) ||
        entry.videoPath == originalVideoPath);
  }

  /// Añade un nuevo video (copia el archivo y genera thumbnail)
  Future<VideoEntry?> addVideo({
    required String originalVideoPath,
    String? customDisplayName,
  }) async {
    try {
      // 1. Verificar que no exista
      if (videoExists(originalVideoPath)) {
        throw Exception('El video ya existe');
      }

      // 2. Copiar el archivo de video
      final copiedVideoPath = await _copyVideoFile(originalVideoPath);

      // 3. Generar thumbnail (solo en móvil)
      String? thumbnailPath;
      if (Platform.isAndroid || Platform.isIOS) {
        thumbnailPath = await _generateThumbnail(copiedVideoPath);
      }

      // 4. Crear entrada
      final displayName = customDisplayName ?? 
          p.basenameWithoutExtension(originalVideoPath);

      final newEntry = VideoEntry(
        videoPath: copiedVideoPath,
        thumbnailPath: thumbnailPath,
        displayName: displayName,
      );

      // 5. Guardar en Hive
      await _box.add(newEntry);

      return newEntry;
    } catch (e) {
      // Si algo falla, limpiar archivos creados
      rethrow;
    }
  }

  /// Copia el archivo de video a la carpeta de la app
  Future<String> _copyVideoFile(String originalPath) async {
    final docDir = await getApplicationDocumentsDirectory();
    final videosDir = Directory(p.join(docDir.path, AppConstants.videosSubdirectory));

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

  /// Genera thumbnail para el video (solo móvil)
  Future<String?> _generateThumbnail(String videoPath) async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final thumbDir = Directory(
          p.join(supportDir.path, AppConstants.thumbnailsSubdirectory));

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

  /// Archiva un video (no lo elimina físicamente)
  Future<void> archiveVideo(VideoEntry entry) async {
    entry.isArchived = true;
    await entry.save();
  }

  /// Restaura un video archivado
  Future<void> unarchiveVideo(VideoEntry entry) async {
    entry.isArchived = false;
    await entry.save();
  }

  /// Elimina un video permanentemente (archivo + datos)
  Future<void> deleteVideoPermanently(VideoEntry entry) async {
    try {
      // 1. Eliminar archivo de video
      await _deleteFile(entry.videoPath);

      // 2. Eliminar thumbnail si existe
      if (entry.thumbnailPath != null) {
        await _deleteFile(entry.thumbnailPath!);
      }

      // 3. Eliminar de Hive
      await entry.delete();
    } catch (e) {
      print('Error eliminando video: $e');
      rethrow;
    }
  }

  /// Renombra el displayName de un video
  Future<void> renameVideo(VideoEntry entry, String newName) async {
    if (newName.trim().isEmpty) {
      throw Exception('El nombre no puede estar vacío');
    }
    entry.displayName = newName.trim();
    await entry.save();
  }

  /// Elimina un archivo de manera segura
  Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error eliminando archivo $path: $e');
    }
  }

  /// Obtiene un stream de cambios en la caja
  Stream<BoxEvent> get changesStream => _box.watch();

  /// Cierra la caja (llamar al cerrar la app)
  Future<void> close() async {
    await _box.close();
  }
}