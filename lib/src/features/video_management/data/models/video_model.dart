// lib/src/features/video_management/data/models/video_model.dart
import 'package:hive/hive.dart';
import '../../domain/entities/video.dart';

part 'video_model.g.dart';

/// Modelo de datos para persistencia con Hive
/// Se encarga de la serialización/deserialización
@HiveType(typeId: 0)
class VideoModel extends HiveObject {
  @HiveField(0)
  String videoPath;

  @HiveField(1)
  final List<String> tags;

  @HiveField(2)
  String? thumbnailPath;

  @HiveField(3)
  String? displayName;

  @HiveField(4)
  bool isArchived;

  @HiveField(5)
  final int createdAtMillis;

  VideoModel({
    required this.videoPath,
    this.tags = const [],
    this.thumbnailPath,
    this.displayName,
    this.isArchived = false,
    required this.createdAtMillis,
  });

  /// Convierte el modelo a una entidad de dominio
  Video toEntity() {
    return Video(
      id: key.toString(), // Usa la key de Hive como ID
      videoPath: videoPath,
      tags: List<String>.from(tags),
      thumbnailPath: thumbnailPath,
      displayName: displayName,
      isArchived: isArchived,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
    );
  }

  /// Crea un modelo desde una entidad de dominio
  factory VideoModel.fromEntity(Video video) {
    return VideoModel(
      videoPath: video.videoPath,
      tags: video.tags,
      thumbnailPath: video.thumbnailPath,
      displayName: video.displayName,
      isArchived: video.isArchived,
      createdAtMillis: video.createdAt.millisecondsSinceEpoch,
    );
  }

  /// Crea una copia del modelo con algunos campos modificados
  VideoModel copyWith({
    String? videoPath,
    List<String>? tags,
    String? thumbnailPath,
    String? displayName,
    bool? isArchived,
    int? createdAtMillis,
  }) {
    return VideoModel(
      videoPath: videoPath ?? this.videoPath,
      tags: tags ?? this.tags,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      displayName: displayName ?? this.displayName,
      isArchived: isArchived ?? this.isArchived,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    );
  }

  @override
  String toString() {
    return 'VideoModel(videoPath: $videoPath, tags: $tags, '
           'displayName: $displayName, isArchived: $isArchived)';
  }
}