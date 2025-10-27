// lib/src/features/video_management/presentation/providers/video_provider.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/video.dart';
import '../../domain/usecases/get_active_videos.dart';
import '../../domain/usecases/add_video.dart';
import '../../domain/usecases/archive_video.dart';
import '../../domain/usecases/delete_video.dart';
import '../../domain/usecases/rename_video.dart';
import '../../domain/usecases/add_tag_to_video.dart';
import '../../domain/usecases/remove_tag_from_video.dart';
import '../../domain/usecases/get_all_tags.dart';

/// Provider optimizado para gestionar el estado de los videos en la UI
class VideoProvider extends ChangeNotifier {
  final GetActiveVideos getActiveVideos;
  final AddVideo addVideo;
  final ArchiveVideo archiveVideo;
  final DeleteVideo deleteVideo;
  final RenameVideo renameVideo;
  final AddTagToVideo addTagToVideo;
  final RemoveTagFromVideo removeTagFromVideo;
  final GetAllTags getAllTags;

  VideoProvider({
    required this.getActiveVideos,
    required this.addVideo,
    required this.archiveVideo,
    required this.deleteVideo,
    required this.renameVideo,
    required this.addTagToVideo,
    required this.removeTagFromVideo,
    required this.getAllTags,
  });

  // Estado
  List<Video> _videos = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _loadingMessage = '';

  // Getters
  List<Video> get videos => List.unmodifiable(_videos); // Retornar lista inmutable
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get loadingMessage => _loadingMessage;

  /// Carga todos los videos activos
  Future<void> loadVideos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await getActiveVideos();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (videos) {
        _videos = videos;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Añade un nuevo video
  Future<bool> addNewVideo(
    String path, {
    String? displayName,
  }) async {
    _isLoading = true;
    _loadingMessage = 'Copiando video...';
    notifyListeners();

    final result = await addVideo(
      originalVideoPath: path,
      customDisplayName: displayName,
    );

    _isLoading = false;
    _loadingMessage = '';

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (video) {
        _videos = [..._videos, video]; // Crear nueva lista
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Archiva un video
  Future<bool> archiveVideoById(String videoId) async {
    final result = await archiveVideo(videoId);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _videos = _videos.where((v) => v.id != videoId).toList(); // Nueva lista
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Elimina un video permanentemente
  Future<bool> deleteVideoById(String videoId) async {
    _isLoading = true;
    _loadingMessage = 'Eliminando permanentemente...';
    notifyListeners();

    final result = await deleteVideo(videoId);

    _isLoading = false;
    _loadingMessage = '';

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _videos = _videos.where((v) => v.id != videoId).toList(); // Nueva lista
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Renombra un video - Optimizado para notificar solo el cambio específico
  Future<bool> renameVideoById(String videoId, String newName) async {
    final result = await renameVideo(videoId, newName);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        final index = _videos.indexWhere((v) => v.id == videoId);
        if (index != -1) {
          final updatedVideo = _videos[index].copyWith(displayName: newName);
          _videos = [
            ..._videos.sublist(0, index),
            updatedVideo,
            ..._videos.sublist(index + 1),
          ];
          notifyListeners();
        }
        return true;
      },
    );
  }

  /// Añade un tag a un video - Optimizado
  Future<bool> addTag(String videoId, String tag) async {
    final result = await addTagToVideo(videoId, tag);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        final index = _videos.indexWhere((v) => v.id == videoId);
        if (index != -1) {
          final updatedVideo = _videos[index].addTag(tag);
          _videos = [
            ..._videos.sublist(0, index),
            updatedVideo,
            ..._videos.sublist(index + 1),
          ];
          notifyListeners();
        }
        return true;
      },
    );
  }

  /// Elimina un tag de un video - Optimizado
  Future<bool> removeTag(String videoId, String tag) async {
    final result = await removeTagFromVideo(videoId, tag);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        final index = _videos.indexWhere((v) => v.id == videoId);
        if (index != -1) {
          final updatedVideo = _videos[index].removeTag(tag);
          _videos = [
            ..._videos.sublist(0, index),
            updatedVideo,
            ..._videos.sublist(index + 1),
          ];
          notifyListeners();
        }
        return true;
      },
    );
  }

  /// Obtiene un video por ID - Sin notificaciones
  Video? getVideoById(String videoId) {
    try {
      return _videos.firstWhere((v) => v.id == videoId);
    } catch (e) {
      return null;
    }
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}