// lib/src/features/video_data/models/video_entry.dart
import 'package:hive/hive.dart';
part 'video_entry.g.dart'; // Asegúrate que este archivo se actualice

@HiveType(typeId: 0)
class VideoEntry extends HiveObject {
  @HiveField(0)
  String videoPath; // Path de la copia interna

  @HiveField(1)
  List<String> tags;

  @HiveField(2)
  String? thumbnailPath;

  @HiveField(3)
  String? displayName;

  @HiveField(4)
  bool isArchived;
  // ---------------------------------

  // Constructor actualizado
  VideoEntry({
    required this.videoPath,
    List<String>? tags,
    this.thumbnailPath,
    this.displayName,
    this.isArchived = false, // Valor por defecto es false
  }) : tags = tags ?? [];

  // --- Métodos addTag y removeTag (sin cambios) ---
  void addTag(String tag) {
    if (!tags.contains(tag) && tag.trim().isNotEmpty) {
      tags.add(tag.trim());
      save();
    }
  }
  void removeTag(String tag) {
    tags.remove(tag);
    save();
  }
  // ------------------------------------------

  @override
  String toString() {
     return 'VideoEntry(videoPath: $videoPath, tags: $tags, displayName: $displayName, thumbnailPath: $thumbnailPath, isArchived: $isArchived)';
  }
}