
// lib/src/features/video_management/domain/usecases/add_tag_to_video.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/video_repository.dart';

class AddTagToVideo {
  final VideoRepository repository;

  AddTagToVideo(this.repository);

  Future<Either<Failure, void>> call(String videoId, String tag) async {
    if (videoId.isEmpty) {
      return const Left(
        ValidationFailure('El ID del video no puede estar vacío')
      );
    }

    if (tag.trim().isEmpty) {
      return const Left(
        ValidationFailure('El tag no puede estar vacío')
      );
    }

    return await repository.addTag(videoId, tag.trim());
  }
}
