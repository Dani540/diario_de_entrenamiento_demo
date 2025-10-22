import 'package:diario_de_entrenamiento_demo/src/app.dart';
import 'package:diario_de_entrenamiento_demo/src/features/video_data/models/video_entry.dart';
import 'package:diario_de_entrenamiento_demo/src/features/video_data/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Obtener directorio de documentos y inicializar Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  // Registra el adaptador generado para VideoEntry
  Hive.registerAdapter(VideoEntryAdapter()); 
  // Abre la caja antes de ejecutar la app
  await DatabaseService.openBox();
  runApp(const MyApp());
}
