// lib/src/features/gallery/screens/gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para preferencias
import 'package:video_thumbnail/video_thumbnail.dart';       // Para thumbnails (Android/iOS)
import 'package:path/path.dart' as p;                      // Para manipulación de rutas
import 'dart:io';                                         // Para File, Directory, Platform

// Importaciones locales
import '../../video_data/models/video_entry.dart';
import '../../video_data/services/video_picker_service.dart';
import '../../analyzer/screens/analyzer_screen.dart'; // Necesario para la navegación en _showItemMenu
import '../../instructor/screens/instructor_screen.dart'; // Necesario para la navegación en _showItemMenu
import '../widgets/video_grid_item.dart'; // Importa el widget componentizado

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final VideoPickerService _pickerService = VideoPickerService();
  // Acceso directo a la caja de Hive
  final Box<VideoEntry> _videoBox = Hive.box<VideoEntry>('videoEntriesBox');

  // Estado para UI
  int _crossAxisCount = 3; // Valor por defecto
  bool _isLoading = false;
  String _loadingMessage = '';

  // Clave para guardar preferencia de tamaño de cuadrícula
  static const String _gridSizePrefKey = 'gallery_grid_size';

  @override
  void initState() {
    super.initState();
    _loadGridSizePreference(); // Carga la preferencia al iniciar
  }

  // --- Carga/Guarda Preferencia de Tamaño de Cuadrícula ---
  Future<void> _loadGridSizePreference() async {
    // Si estamos en web, shared_preferences puede no funcionar sin configuración extra.
    // Usaremos valores por defecto por ahora en web.
     if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || Platform.isAndroid || Platform.isIOS) {
       try {
         final prefs = await SharedPreferences.getInstance();
         setState(() {
           _crossAxisCount = prefs.getInt(_gridSizePrefKey) ?? 3;
         });
       } catch (e) {
          // Error al cargar preferencias, usar valor por defecto
          _crossAxisCount = 3;
       }
    } else {
       _crossAxisCount = 3; // Valor por defecto para web/otras
    }
  }

  Future<void> _saveGridSizePreference(int count) async {
    setState(() {
      _crossAxisCount = count; // Actualiza UI inmediatamente
    });
     if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || Platform.isAndroid || Platform.isIOS) {
       try {
         final prefs = await SharedPreferences.getInstance();
         await prefs.setInt(_gridSizePrefKey, count);
       } catch (e) {
         if (mounted) _showSnackBar('Error al guardar preferencia de tamaño.');
       }
     }
  }
  // ----------------------------------------------------

  // --- FUNCIÓN PARA AÑADIR VIDEO (CON COPIA Y THUMBNAIL CONDICIONAL) ---
  Future<void> _addVideo() async {
    final originalVideoPath = await _pickerService.pickVideoFromGallery();

    if (!mounted || originalVideoPath == null) {
      if (mounted) _showSnackBar('No se seleccionó video o permiso denegado.');
      return;
    }

    // Comprobar si ya existe ANTES de copiar y generar thumbnail
     bool exists = _videoBox.values.any((entry) {
        // Comparamos nombre base y original path por si acaso
        return p.basename(entry.videoPath) == p.basename(originalVideoPath) || entry.videoPath == originalVideoPath;
     });
     if (exists) {
        _showSnackBar('Este video (o uno con el mismo nombre) ya está en tu diario.');
        return;
     }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Copiando video...';
    });

    String? copiedVideoPath;
    String? thumbnailFilePath;

    try {
      // --- 1. Copiar el Video ---
      final docDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory(p.join(docDir.path, 'videos'));
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }
      final String fileExtension = p.extension(originalVideoPath);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String uniqueFileName = 'video_$timestamp$fileExtension';
      copiedVideoPath = p.join(videosDir.path, uniqueFileName);

      final File originalFile = File(originalVideoPath);
      await originalFile.copy(copiedVideoPath);

      // --- 2. Generar Miniatura Condicionalmente (Android/iOS) ---
      thumbnailFilePath = null; // Inicializa como null
      if (Platform.isAndroid || Platform.isIOS) {
        setState(() { _loadingMessage = 'Generando miniatura...'; });
        try {
           final supportDir = await getApplicationSupportDirectory();
           final thumbDir = Directory(p.join(supportDir.path, 'thumbnails'));
           if (!await thumbDir.exists()) {
             await thumbDir.create(recursive: true);
           }
           thumbnailFilePath = await VideoThumbnail.thumbnailFile(
             video: copiedVideoPath, // Usa la ruta de la copia
             thumbnailPath: thumbDir.path,
             imageFormat: ImageFormat.JPEG,
             maxWidth: 200,
             quality: 80,
           );
        } catch (thumbError) {
          if (mounted) _showSnackBar('No se pudo generar la miniatura: $thumbError');
          thumbnailFilePath = null;
        }
      }

      // --- 3. Añadir a Hive ---
      final newEntry = VideoEntry(
        videoPath: copiedVideoPath, // Guarda la ruta de la COPIA
        thumbnailPath: thumbnailFilePath, // Puede ser null
        displayName: p.basenameWithoutExtension(originalVideoPath), // Nombre inicial
      );
      await _videoBox.add(newEntry);

      if (mounted) _showSnackBar('Video añadido con éxito.');

    } catch (e) {
      if (mounted) _showSnackBar('Error al procesar video: $e');
      if (copiedVideoPath != null) await _tryDeleteFile(copiedVideoPath);
      if (thumbnailFilePath != null) await _tryDeleteFile(thumbnailFilePath);
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; _loadingMessage = ''; });
      }
    }
  }
  // ----------------------------------------------------------------

  // --- FUNCIÓN PARA ELIMINAR VIDEO ---
  Future<void> _deleteVideo(VideoEntry entry) async {
    final String nameToShow = entry.displayName ?? p.basename(entry.videoPath);
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Seguro que quieres eliminar "$nameToShow"? Se borrará el video copiado y la miniatura.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && mounted) {
      setState(() { _isLoading = true; _loadingMessage = 'Eliminando...'; });
      try {
        // 1. Eliminar archivo de miniatura
        if (entry.thumbnailPath != null) {
          await _tryDeleteFile(entry.thumbnailPath!);
        }
        // 2. Eliminar archivo de video COPIADO
        await _tryDeleteFile(entry.videoPath); // entry.videoPath apunta a la copia

        // 3. Eliminar la entrada de Hive
        await entry.delete();

        if (mounted) _showSnackBar('Video eliminado.');

      } catch (e) {
        if (mounted) _showSnackBar('Error al eliminar el video: $e');
      } finally {
         if (mounted) setState(() { _isLoading = false; _loadingMessage = ''; });
      }
    }
  }
  // ----------------------------------------------------

  // --- FUNCIÓN PARA RENOMBRAR VIDEO ---
  Future<void> _renameVideo(VideoEntry entry) async {
    final TextEditingController renameController = TextEditingController();
    renameController.text = entry.displayName ?? p.basenameWithoutExtension(entry.videoPath);

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar Clip'),
        content: TextField(
          controller: renameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nuevo nombre'),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Guardar'),
            onPressed: () => Navigator.of(context).pop(renameController.text.trim()),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != entry.displayName) {
      entry.displayName = newName;
      await entry.save();
      if(mounted) _showSnackBar('Video renombrado.');
    } else if (newName != null && newName.isEmpty) {
       if(mounted) _showSnackBar('El nombre no puede estar vacío.');
    }
  }
  // ------------------------------------

  // --- Navegaciones (Ahora solo instructor, el analizador se llama desde VideoGridItem) ---
  void _navigateToInstructor() {
     Navigator.push(
       context,
       MaterialPageRoute(builder: (context) => const InstructorScreen()),
     );
  }
  // ------------------------------------------------------------------------------------

  // --- Helper para mostrar SnackBar ---
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
  // ---------------------------------

  // --- Helper para borrar archivos de forma segura ---
  Future<void> _tryDeleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
       // Error silencioso al borrar archivo, opcionalmente loggear
    }
  }
  // ------------------------------------------

  // --- Menú Contextual (llamado por VideoGridItem) ---
  void _showItemMenu(BuildContext itemContext, VideoEntry entry, Offset tapPosition) {
    // Usa itemContext (el contexto del Builder dentro del itemBuilder)
    final RenderBox overlay = Overlay.of(itemContext).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: itemContext, // Usa el contexto correcto
      position: RelativeRect.fromRect(
         // Crea un Rect pequeño en la posición del tap para anclar el menú
         Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 1, 1),
         Offset.zero & overlay.size // Límites del overlay
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'rename',
          child: const ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Renombrar'),
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red[400]),
            title: Text('Eliminar', style: TextStyle(color: Colors.red[400])),
            dense: true,
          ),
        ),
      ],
      elevation: 8.0,
    ).then<void>((String? value) { // Callback después de seleccionar o cerrar
      if (value == 'rename') {
        // Necesitamos el contexto principal para mostrar el diálogo,
        // por eso es mejor llamar a _renameVideo desde aquí (el State).
        _renameVideo(entry);
      } else if (value == 'delete') {
        _deleteVideo(entry);
      }
    });
  }
  // ----------------------------------------------------


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Diario'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
           PopupMenuButton<int>(
              initialValue: _crossAxisCount,
              onSelected: _saveGridSizePreference, // Llama a la función que guarda y actualiza
              icon: Icon( // Icono dinámico
                _crossAxisCount == 2 ? Icons.grid_view_sharp
                : _crossAxisCount == 3 ? Icons.grid_view_rounded
                : Icons.grid_4x4_rounded
              ),
              tooltip: 'Tamaño de cuadrícula',
              itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                 const PopupMenuItem<int>( value: 2, child: Text('2 Columnas')),
                 const PopupMenuItem<int>( value: 3, child: Text('3 Columnas')),
                 const PopupMenuItem<int>( value: 4, child: Text('4 Columnas')),
               ],
           )
        ],
      ),
      // Stack para el overlay de carga
      body: Stack(
        children: [
          ValueListenableBuilder<Box<VideoEntry>>(
            valueListenable: _videoBox.listenable(),
            builder: (context, box, _) {
              final videoEntries = box.values.toList();

              if (videoEntries.isEmpty && !_isLoading) {
                return const Center(
                   child: Padding(
                     padding: EdgeInsets.all(20.0),
                     child: Text(
                       'Aún no has añadido videos.\nUsa el menú (+) para empezar.', // Mensaje actualizado
                       textAlign: TextAlign.center,
                       style: TextStyle(fontSize: 16, color: Colors.grey),
                     ),
                   ),
                );
              }

              // --- GridView Refactorizado ---
              return GridView.builder(
                // Key para forzar reconstrucción si cambia el número de columnas
                key: ValueKey('grid_$_crossAxisCount'),
                padding: const EdgeInsets.all(12.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount, // Usa el estado
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.8, // Relación ancho/alto
                ),
                itemCount: videoEntries.length,
                itemBuilder: (context, index) {
                  final entry = videoEntries[index];
                  // Usa Builder para asegurar un context correcto para _showItemMenu
                  return Builder(
                     builder: (itemContext) {
                        return VideoGridItem(
                          entry: entry,
                          // Pasa la función _showItemMenu como callback
                          onLongPress: (ctx, videoEntry, position) => _showItemMenu(ctx, videoEntry, position),
                        );
                     }
                  );
                },
              );
              // -----------------------------
            },
          ), // Fin ValueListenableBuilder

          // --- Overlay de Carga ---
           if (_isLoading)
             Positioned.fill( // Ocupa toda la pantalla
               child: Container(
                 color: Colors.black.withAlpha((255*0.6).round()), // Fondo semitransparente
                 child: Center(
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                     decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.surface,
                       borderRadius: BorderRadius.circular(12),
                       boxShadow: kElevationToShadow[4], // Sombra sutil
                     ),
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const CircularProgressIndicator(),
                         const SizedBox(height: 16),
                         Text(
                           _loadingMessage,
                           style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                           textAlign: TextAlign.center,
                         ),
                       ],
                     ),
                   ),
                 ),
               ),
             ),
          // ------------------------
        ], // Fin Stack principal
      ),
       // El FloatingActionButton ahora está en MainScreen
    );
  } // Fin build()

} // Fin _GalleryScreenState