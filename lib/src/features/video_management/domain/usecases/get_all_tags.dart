
// lib/src/features/video_management/domain/usecases/get_all_tags.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/video_repository.dart';

class GetAllTags {
  final VideoRepository repository;

  GetAllTags(this.repository);

  Future<Either<Failure, List<String>>> call({
    bool includeArchived = false,
  }) async {
    return await repository.getAllTags(includeArchived: includeArchived);
  }
}