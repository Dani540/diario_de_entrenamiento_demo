// lib/src/features/video_management/domain/repositories/video_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/video.dart';

/// Interfaz abstracta del repositorio de videos
/// Define el contrato que debe cumplir cualquier implementación
abstract class VideoRepository {
  
  /// Obtiene todos los videos activos (no archivados)
  Future<Either<Failure, List<Video>>> getActiveVideos();
  
  /// Obtiene todos los videos (incluyendo archivados)
  Future<Either<Failure, List<Video>>> getAllVideos();
  
  /// Obtiene un video por su ID
  Future<Either<Failure, Video>> getVideoById(String videoId);
  
  /// Añade un nuevo video desde una ruta original
  Future<Either<Failure, Video>> addVideo({
    required String originalVideoPath,
    String? customDisplayName,
  });
  
  /// Archiva un video (no lo elimina físicamente)
  Future<Either<Failure, void>> archiveVideo(String videoId);
  
  /// Desarchiva un video previamente archivado
  Future<Either<Failure, void>> unarchiveVideo(String videoId);
  
  /// Elimina un video permanentemente (archivo + datos)
  Future<Either<Failure, void>> deleteVideo(String videoId);
  
  /// Renombra el displayName de un video
  Future<Either<Failure, void>> renameVideo(String videoId, String newName);
  
  /// Añade un tag a un video
  Future<Either<Failure, void>> addTag(String videoId, String tag);
  
  /// Elimina un tag de un video
  Future<Either<Failure, void>> removeTag(String videoId, String tag);
  
  /// Obtiene todos los tags únicos de los videos
  Future<Either<Failure, List<String>>> getAllTags({bool includeArchived = false});
  
  /// Verifica si un video ya existe por su ruta
  bool videoExists(String videoPath);
  
  /// Stream de cambios en los videos
  Stream<List<Video>> watchVideos();
}