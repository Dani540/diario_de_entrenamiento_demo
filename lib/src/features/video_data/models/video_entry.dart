import 'package:hive/hive.dart';

part 'video_entry.g.dart'; // Archivo generado por Hive

@HiveType(typeId: 0) // typeId debe ser único para cada modelo Hive
class VideoEntry extends HiveObject {
  @HiveField(0) // Índice único para cada campo
  final String videoPath;

  @HiveField(1)
  List<String> tags;

  // Constructor
  VideoEntry({required this.videoPath, List<String>? tags}) : tags = tags ?? [];

  // Método para añadir un tag
  void addTag(String tag) {
    if (!tags.contains(tag) && tag.trim().isNotEmpty) {
      tags.add(tag.trim());
      save(); // Guarda el objeto en Hive después de modificarlo
    }
  }

  // Método para eliminar un tag
  void removeTag(String tag) {
    tags.remove(tag);
    save(); // Guarda el objeto en Hive
  }

  @override
  String toString() {
    return 'VideoEntry(videoPath: $videoPath, tags: $tags)';
  }
}