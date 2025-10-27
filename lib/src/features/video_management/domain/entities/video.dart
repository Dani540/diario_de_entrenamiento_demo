// lib/src/features/video_management/domain/entities/video.dart
import 'package:equatable/equatable.dart';

/// Entidad de dominio pura para Video
/// No tiene dependencias de frameworks externos (sin Hive, sin Flutter)
class Video extends Equatable {
  final String id;
  final String videoPath;
  final List<String> tags;
  final String? thumbnailPath;
  final String? displayName;
  final bool isArchived;
  final DateTime createdAt;

  const Video({
    required this.id,
    required this.videoPath,
    this.tags = const [],
    this.thumbnailPath,
    this.displayName,
    this.isArchived = false,
    required this.createdAt,
  });

  /// Crea una copia del video con algunos campos modificados
  Video copyWith({
    String? id,
    String? videoPath,
    List<String>? tags,
    String? thumbnailPath,
    String? displayName,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return Video(
      id: id ?? this.id,
      videoPath: videoPath ?? this.videoPath,
      tags: tags ?? this.tags,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      displayName: displayName ?? this.displayName,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Añade un tag al video
  Video addTag(String tag) {
    if (tags.contains(tag) || tag.trim().isEmpty) {
      return this;
    }
    return copyWith(tags: [...tags, tag.trim()]);
  }

  /// Elimina un tag del video
  Video removeTag(String tag) {
    return copyWith(tags: tags.where((t) => t != tag).toList());
  }

  /// Archiva el video
  Video archive() => copyWith(isArchived: true);

  /// Desarchiva el video
  Video unarchive() => copyWith(isArchived: false);

  @override
  List<Object?> get props => [
    id,
    videoPath,
    tags,
    thumbnailPath,
    displayName,
    isArchived,
    createdAt,
  ];

  @override
  String toString() {
    return 'Video(id: $id, videoPath: $videoPath, tags: $tags, '
           'displayName: $displayName, isArchived: $isArchived)';
  }
}