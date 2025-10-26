// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'src/app.dart';
import 'src/features/video_data/models/video_entry.dart';
import 'src/core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Hive
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    // Registrar adaptador
    Hive.registerAdapter(VideoEntryAdapter());

    // Limpiar las cajas existentes para evitar datos corruptos
    await Hive.deleteBoxFromDisk(AppConstants.videoEntriesBoxName);

    // Abrir la caja de videos
    await Hive.openBox<VideoEntry>(AppConstants.videoEntriesBoxName);

    // Ejecutar la app
    runApp(const MyApp());
  } catch (e, stackTrace) {
    // Log del error para debugging
    print('Error durante la inicialización: $e');
    print('StackTrace: $stackTrace');

    // Ejecutar la app con un error screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error al inicializar la aplicación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}