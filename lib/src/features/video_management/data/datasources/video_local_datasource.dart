// lib/src/features/video_management/data/datasources/video_local_datasource.dart
import 'package:hive/hive.dart';
import '../models/video_model.dart';

/// Interfaz para el DataSource local de videos
abstract class VideoLocalDataSource {
  Future<List<VideoModel>> getAllVideos();
  Future<VideoModel> getVideoById(String id);
  Future<String> saveVideo(VideoModel video);
  Future<void> updateVideo(String id, VideoModel video);
  Future<void> deleteVideo(String id);
  Stream<BoxEvent> watchVideos();
}

/// Implementación del DataSource local usando Hive
class VideoLocalDataSourceImpl implements VideoLocalDataSource {
  final Box<VideoModel> box;

  VideoLocalDataSourceImpl(this.box);

  @override
  Future<List<VideoModel>> getAllVideos() async {
    return box.values.toList();
  }

  @override
  Future<VideoModel> getVideoById(String id) async {
    final video = box.get(id);
    if (video == null) {
      throw Exception('Video con ID $id no encontrado');
    }
    return video;
  }

  @override
  Future<String> saveVideo(VideoModel video) async {
    final key = await box.add(video);
    return key.toString();
  }

  @override
  Future<void> updateVideo(String id, VideoModel video) async {
    await box.put(id, video);
  }

  @override
  Future<void> deleteVideo(String id) async {
    await box.delete(id);
  }

  @override
  Stream<BoxEvent> watchVideos() {
    return box.watch();
  }
}


