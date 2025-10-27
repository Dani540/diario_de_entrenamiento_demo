// lib/src/features/video_management/domain/usecases/get_active_videos.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';

class GetActiveVideos {
  final VideoRepository repository;

  GetActiveVideos(this.repository);

  Future<Either<Failure, List<Video>>> call() async {
    return await repository.getActiveVideos();
  }
}