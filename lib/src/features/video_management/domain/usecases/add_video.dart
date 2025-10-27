
// lib/src/features/video_management/domain/usecases/add_video.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';

class AddVideo {
  final VideoRepository repository;

  AddVideo(this.repository);

  Future<Either<Failure, Video>> call({
    required String originalVideoPath,
    String? customDisplayName,
  }) async {
    // Validaciones de negocio
    if (originalVideoPath.isEmpty) {
      return const Left(
        ValidationFailure('La ruta del video no puede estar vacía')
      );
    }

    if (repository.videoExists(originalVideoPath)) {
      return const Left(
        ValidationFailure('Este video ya existe')
      );
    }

    return await repository.addVideo(
      originalVideoPath: originalVideoPath,
      customDisplayName: customDisplayName,
    );
  }
}