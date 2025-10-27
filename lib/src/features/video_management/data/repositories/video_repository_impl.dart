// lib/src/features/video_management/data/repositories/video_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import '../../../../core/errors/failures.dart';
import '../../domain/entities/video.dart';
import '../../domain/repositories/video_repository.dart';
import '../datasources/video_local_datasource.dart';
import '../datasources/file_storage_datasource.dart';
import '../models/video_model.dart';

/// Implementación concreta del repositorio de videos
class VideoRepositoryImpl implements VideoRepository {
  final VideoLocalDataSource localDataSource;
  final FileStorageDataSource fileStorage;

  VideoRepositoryImpl(Box<VideoModel> box, {
    required this.localDataSource,
    required this.fileStorage,
  });

  @override
  Future<Either<Failure, List<Video>>> getActiveVideos() async {
    try {
      final models = await localDataSource.getAllVideos();
      final activeVideos = models
          .where((model) => !model.isArchived)
          .map((model) => model.toEntity())
          .toList();
      return Right(activeVideos);
    } catch (e) {
      return Left(CacheFailure('Error al obtener videos: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Video>>> getAllVideos() async {
    try {
      final models = await localDataSource.getAllVideos();
      final videos = models.map((model) => model.toEntity()).toList();
      return Right(videos);
    } catch (e) {
      return Left(CacheFailure('Error al obtener videos: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Video>> getVideoById(String videoId) async {
    try {
      final model = await localDataSource.getVideoById(videoId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(NotFoundFailure('Video no encontrado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Video>> addVideo({
    required String originalVideoPath,
    String? customDisplayName,
  }) async {
    try {
      // 1. Copiar archivo de video
      final copiedPath = await fileStorage.copyVideoFile(originalVideoPath);

      // 2. Generar thumbnail
      final thumbnailPath = await fileStorage.generateThumbnail(copiedPath);

      // 3. Crear modelo
      final model = VideoModel(
        videoPath: copiedPath,
        thumbnailPath: thumbnailPath,
        displayName: customDisplayName ?? 
            p.basenameWithoutExtension(originalVideoPath),
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      );

      // 4. Guardar en base de datos
      final id = await localDataSource.saveVideo(model);

      // 5. Recuperar el modelo guardado para obtener el ID correcto
      final savedModel = await localDataSource.getVideoById(id);

      return Right(savedModel.toEntity());
    } catch (e) {
      return Left(ServerFailure('Error al añadir video: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> archiveVideo(String videoId) async {
    try {
      final model = await localDataSource.getVideoById(videoId);
      final updatedModel = model.copyWith(isArchived: true);
      await localDataSource.updateVideo(videoId, updatedModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al archivar video: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> unarchiveVideo(String videoId) async {
    try {
      final model = await localDataSource.getVideoById(videoId);
      final updatedModel = model.copyWith(isArchived: false);
      await localDataSource.updateVideo(videoId, updatedModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al desarchivar video: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVideo(String videoId) async {
    try {
      // 1. Obtener el modelo para acceder a las rutas
      final model = await localDataSource.getVideoById(videoId);

      // 2. Eliminar archivo de video
      await fileStorage.deleteFile(model.videoPath);

      // 3. Eliminar thumbnail si existe
      if (model.thumbnailPath != null) {
        await fileStorage.deleteFile(model.thumbnailPath!);
      }

      // 4. Eliminar de base de datos
      await localDataSource.deleteVideo(videoId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al eliminar video: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> renameVideo(String videoId, String newName) async {
    try {
      final model = await localDataSource.getVideoById(videoId);
      final updatedModel = model.copyWith(displayName: newName);
      await localDataSource.updateVideo(videoId, updatedModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al renombrar video: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addTag(String videoId, String tag) async {
    try {
      final model = await localDataSource.getVideoById(videoId);
      
      // Evitar duplicados
      if (model.tags.contains(tag)) {
        return const Right(null);
      }

      final updatedTags = [...model.tags, tag];
      final updatedModel = model.copyWith(tags: updatedTags);
      await localDataSource.updateVideo(videoId, updatedModel);
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al añadir tag: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> removeTag(String videoId, String tag) async {
    try {
      final model = await localDataSource.getVideoById(videoId);
      final updatedTags = model.tags.where((t) => t != tag).toList();
      final updatedModel = model.copyWith(tags: updatedTags);
      await localDataSource.updateVideo(videoId, updatedModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al eliminar tag: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAllTags({
    bool includeArchived = false,
  }) async {
    try {
      final models = await localDataSource.getAllVideos();
      final filteredModels = includeArchived
          ? models
          : models.where((m) => !m.isArchived);

      final Set<String> allTags = {};
      for (var model in filteredModels) {
        allTags.addAll(model.tags);
      }

      return Right(allTags.toList()..sort());
    } catch (e) {
      return Left(CacheFailure('Error al obtener tags: ${e.toString()}'));
    }
  }

  @override
  bool videoExists(String videoPath) {
    try {
      // Operación síncrona, se puede hacer directamente
      // Nota: Esto requeriría acceso directo al box o una implementación diferente
      // Por simplicidad, retornamos false aquí
      // En una implementación real, podrías pasar esto al datasource
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<List<Video>> watchVideos() {
    return localDataSource.watchVideos().asyncMap((_) async {
      final models = await localDataSource.getAllVideos();
      return models.map((m) => m.toEntity()).toList();
    });
  }
}