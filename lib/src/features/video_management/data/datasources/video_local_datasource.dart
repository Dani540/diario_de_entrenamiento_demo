// lib/src/features/video_management/data/datasources/video_local_datasource.dart
import 'package:hive/hive.dart';
import '../models/video_model.dart';

abstract class VideoLocalDataSource {
  Future<List<VideoModel>> getAllVideos();
  Future<VideoModel> getVideoById(String id);
  Future<String> saveVideo(VideoModel video);
  Future<void> updateVideo(String id, VideoModel video);
  Future<void> deleteVideo(String id);
  Stream<BoxEvent> watchVideos();
}

class VideoLocalDataSourceImpl implements VideoLocalDataSource {
  final Box<VideoModel> box;

  VideoLocalDataSourceImpl(this.box);

  @override
  Future<List<VideoModel>> getAllVideos() async {
    return box.values.toList();
  }

  @override
  Future<VideoModel> getVideoById(String id) async {
    // CRITICO: Manejo dual de IDs (int y string)
    VideoModel? video;
    
    try {
      final intId = int.parse(id);
      video = box.get(intId);
    } catch (e) {
      video = box.get(id);
    }
    
    if (video == null) {
      throw Exception('Video con ID $id no encontrado');
    }
    return video;
  }

  @override
  Future<String> saveVideo(VideoModel video) async {
    // CRITICO: add() retorna int, convertimos a String
    final key = await box.add(video);
    
    // CRITICO: Forzar escritura en disco
    await box.flush();
    
    print('[DATASOURCE] Video guardado con ID: $key');
    return key.toString();
  }

  @override
  Future<void> updateVideo(String id, VideoModel video) async {
    // CRITICO: Manejo dual de IDs
    try {
      final intId = int.parse(id);
      await box.put(intId, video);
    } catch (e) {
      await box.put(id, video);
    }
    await box.flush();
  }

  @override
  Future<void> deleteVideo(String id) async {
    // CRITICO: Manejo dual de IDs
    try {
      final intId = int.parse(id);
      await box.delete(intId);
    } catch (e) {
      await box.delete(id);
    }
    await box.flush();
  }

  @override
  Stream<BoxEvent> watchVideos() {
    return box.watch();
  }
}