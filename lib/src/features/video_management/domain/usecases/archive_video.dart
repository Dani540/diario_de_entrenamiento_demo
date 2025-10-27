
// lib/src/features/video_management/domain/usecases/archive_video.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/video_repository.dart';

class ArchiveVideo {
  final VideoRepository repository;

  ArchiveVideo(this.repository);

  Future<Either<Failure, void>> call(String videoId) async {
    if (videoId.isEmpty) {
      return const Left(
        ValidationFailure('El ID del video no puede estar vacío')
      );
    }

    return await repository.archiveVideo(videoId);
  }
}
