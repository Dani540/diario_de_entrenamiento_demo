
// lib/src/features/video_management/domain/usecases/delete_video.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/video_repository.dart';

class DeleteVideo {
  final VideoRepository repository;

  DeleteVideo(this.repository);

  Future<Either<Failure, void>> call(String videoId) async {
    if (videoId.isEmpty) {
      return const Left(
        ValidationFailure('El ID del video no puede estar vacío')
      );
    }

    return await repository.deleteVideo(videoId);
  }
}
