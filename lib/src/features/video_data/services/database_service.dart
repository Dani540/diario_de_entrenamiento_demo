import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/video_entry.dart';

class DatabaseService {
  static const String _boxName = 'videoEntriesBox';

  // Referencia estática a la caja abierta
  static late Box<VideoEntry> _videoEntriesBox;

  // Método para abrir la caja al inicio
  static Future<void> openBox() async {
    _videoEntriesBox = await Hive.openBox<VideoEntry>(_boxName);
  }

  // Obtener todas las entradas de video
  List<VideoEntry> getAllVideoEntries() {
    // Ordenar por algún criterio si es necesario, por ahora tal cual vienen
    return _videoEntriesBox.values.toList();
  }

   // Obtener una entrada específica por su path (actúa como ID único aquí)
  VideoEntry? getVideoEntry(String videoPath) {
    // Hive no tiene un 'get por campo', así que buscamos en la lista
    try {
      return _videoEntriesBox.values.firstWhere((entry) => entry.videoPath == videoPath);
    } catch (e) {
      // Si no se encuentra, firstWhere lanza una excepción
      return null;
    }
  }

  // Añadir una nueva entrada de video (si no existe ya por path)
  Future<void> addVideoEntry(String videoPath) async {
    // Evitar duplicados basados en el path
     if (getVideoEntry(videoPath) == null) {
        final newEntry = VideoEntry(videoPath: videoPath);
        await _videoEntriesBox.add(newEntry); // Hive asigna una clave automática
     } else {
       print("Video con path $videoPath ya existe.");
     }
  }

  // Eliminar una entrada de video (necesitamos la clave de Hive)
  Future<void> deleteVideoEntry(VideoEntry entry) async {
    // HiveObject tiene acceso a su propia clave
    await entry.delete();
  }

   // Actualizar tags (realmente se hace en el modelo VideoEntry con addTag/removeTag)
   // No necesitamos un método específico aquí si modificamos directamente el objeto
   // y llamamos a entry.save()

  // Escuchar cambios en la caja (útil para actualizar UI automáticamente)
  ValueListenable<Box<VideoEntry>> getVideoEntriesListenable() {
    return _videoEntriesBox.listenable();
  }

  // Cerrar la caja (opcional, al cerrar la app)
  Future<void> closeBox() async {
    await _videoEntriesBox.close();
  }
}