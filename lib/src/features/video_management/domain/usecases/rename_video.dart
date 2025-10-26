
// lib/src/features/video_management/domain/usecases/rename_video.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/video_repository.dart';

class RenameVideo {
  final VideoRepository repository;

  RenameVideo(this.repository);

  Future<Either<Failure, void>> call(String videoId, String newName) async {
    if (videoId.isEmpty) {
      return const Left(
        ValidationFailure('El ID del video no puede estar vacío')
      );
    }

    if (newName.trim().isEmpty) {
      return const Left(
        ValidationFailure('El nombre no puede estar vacío')
      );
    }

    return await repository.renameVideo(videoId, newName.trim());
  }
}