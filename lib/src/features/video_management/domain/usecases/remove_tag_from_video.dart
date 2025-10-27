
// lib/src/features/video_management/domain/usecases/remove_tag_from_video.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/video_repository.dart';

class RemoveTagFromVideo {
  final VideoRepository repository;

  RemoveTagFromVideo(this.repository);

  Future<Either<Failure, void>> call(String videoId, String tag) async {
    if (videoId.isEmpty) {
      return const Left(
        ValidationFailure('El ID del video no puede estar vacío')
      );
    }

    return await repository.removeTag(videoId, tag);
  }
}