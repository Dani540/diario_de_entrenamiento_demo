import 'package:diario_de_entrenamiento_demo/src/features/instructor/screens/instructor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Para ValueListenableBuilder
// Asegúrate que las rutas de importación coincidan con tu estructura
import '../../video_data/models/video_entry.dart';
import '../../video_data/services/database_service.dart';
import '../../video_data/services/video_picker_service.dart';
import '../../analyzer/screens/analyzer_screen.dart'; // Importa la pantalla del analizador

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // Usamos 'late final' porque los inicializamos aquí y no cambiarán
  late final DatabaseService _dbService;
  late final VideoPickerService _pickerService;

  @override
  void initState() {
    super.initState();
    // Instanciamos los servicios aquí
    _dbService = DatabaseService();
    _pickerService = VideoPickerService();
  }


  Future<void> _addVideo() async {
    final videoPath = await _pickerService.pickVideoFromGallery();
    // Usamos 'mounted' para asegurarnos que el widget todavía existe
    // antes de interactuar con el contexto o estado.
    if (videoPath != null && mounted) {
      await _dbService.addVideoEntry(videoPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video añadido'), duration: Duration(seconds: 1)),
      );
    } else if (mounted) { // Solo muestra el SnackBar si el widget aún está montado
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se seleccionó video o permiso denegado.')),
      );
    }
  }

  void _navigateToAnalyzer(String videoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyzerScreen(videoPath: videoPath),
      ),
    );
  }

  void _navigateToInstructor() {
     Navigator.push(
       context,
       MaterialPageRoute(builder: (context) => const InstructorScreen()),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Diario'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // Usamos ValueListenableBuilder para que la lista se actualice automáticamente
      // cuando Hive cambie (añadir/eliminar videos)
      body: ValueListenableBuilder<Box<VideoEntry>>(
        // Escuchamos directamente la 'box' de Hive
        valueListenable: Hive.box<VideoEntry>('videoEntriesBox').listenable(),
        builder: (context, box, _) {
          final videoEntries = box.values.toList(); // Obtenemos la lista de videos

          // Mensaje si no hay videos
          if (videoEntries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Aún no has añadido videos.\n¡Presiona el botón "+" para empezar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // --- Cuadrícula para mostrar los videos ---
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Número de columnas
              crossAxisSpacing: 12.0, // Espacio horizontal
              mainAxisSpacing: 12.0, // Espacio vertical
              childAspectRatio: 0.8, // Relación Ancho/Alto (un poco más alto que ancho)
            ),
            itemCount: videoEntries.length,
            itemBuilder: (context, index) {
              final entry = videoEntries[index];
              final videoFileName = entry.videoPath.split('/').last;

              // Widget para cada item de la cuadrícula
              return GestureDetector(
                onTap: () => _navigateToAnalyzer(entry.videoPath),
                child: ClipRRect( // Para bordes redondeados
                  borderRadius: BorderRadius.circular(10.0),
                  child: GridTile(
                    footer: GridTileBar( // Barra inferior con el nombre
                      backgroundColor: Colors.black45,
                      title: Text(
                        videoFileName,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis, // Corta el texto si es muy largo
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    // Placeholder visual para el video
                    child: Container(
                       decoration: BoxDecoration(
                         color: Colors.blueGrey[100],
                         border: Border.all(color: Colors.blueGrey[300]!, width: 0.5)
                       ),
                      child: const Icon(
                        Icons.videocam, // Ícono de video
                        color: Colors.black54,
                        size: 45,
                      ),
                      // TODO: En el futuro, reemplazar esto con un Thumbnail del video
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: SpeedDial(
         icon: Icons.menu, // Icono principal del FAB (menú)
         activeIcon: Icons.close, // Icono cuando está desplegado
         buttonSize: const Size(56.0, 56.0), // Tamaño estándar
         visible: true,
         curve: Curves.bounceIn,
         overlayColor: Colors.black,
         overlayOpacity: 0.5,
         tooltip: 'Opciones',
         heroTag: 'speed-dial-hero-tag', // Necesario si hay múltiples FABs/SpeedDials
         backgroundColor: Theme.of(context).colorScheme.primary,
         foregroundColor: Theme.of(context).colorScheme.onPrimary,
         elevation: 8.0,
         shape: const CircleBorder(),
         children: [
            // Botón para ir al Instructor
            SpeedDialChild(
              child: const Icon(Icons.lightbulb_outline),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              label: 'Instructor',
              labelStyle: const TextStyle(fontSize: 16.0),
              onTap: _navigateToInstructor, // Llama a la función de navegación
            ),
            // Botón para Añadir Video
            SpeedDialChild(
              child: const Icon(Icons.video_call_outlined),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              label: 'Añadir Video',
              labelStyle: const TextStyle(fontSize: 16.0),
              onTap: _addVideo, // Llama a la función de añadir video
            ),
         ],
      ),
    );
  }
}