import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para preferencias
import 'package:video_thumbnail/video_thumbnail.dart';       // Para thumbnails (Android/iOS)
import 'package:path/path.dart' as p;                      // Para manipulación de rutas
import 'dart:io';                                         // Para File, Directory, Platform

// Importaciones locales
import '../../video_data/models/video_entry.dart';
import '../../video_data/services/video_picker_service.dart';
import '../../analyzer/screens/analyzer_screen.dart';
import '../../instructor/screens/instructor_screen.dart';


class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final VideoPickerService _pickerService = VideoPickerService();
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
    _loadGridSizePreference();
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
          // print("Error cargando preferencias: $e"); // Quitado print
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
         // print("Error guardando preferencias: $e"); // Quitado print
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
        // Comparamos el nombre base y quizás el tamaño para robustez, ya que la ruta interna será diferente
        // Por ahora, solo comparamos el nombre de archivo original.
        return p.basename(entry.videoPath) == p.basename(originalVideoPath) || entry.videoPath == originalVideoPath;
        // Podríamos hacer una comparación más robusta si guardamos el path original en otro campo
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
           // Usamos el video COPIADO para generar la miniatura
           thumbnailFilePath = await VideoThumbnail.thumbnailFile(
             video: copiedVideoPath, // ¡Usa la ruta de la copia!
             thumbnailPath: thumbDir.path,
             imageFormat: ImageFormat.JPEG,
             maxWidth: 200,
             quality: 80,
           );
        } catch (thumbError) {
          // print("Error al generar thumbnail con video_thumbnail: $thumbError"); // Quitado print
          if (mounted) _showSnackBar('No se pudo generar la miniatura: $thumbError');
          thumbnailFilePath = null; // Asegura que sea null si falla
        }
      } else {
         // print("Generación de thumbnail no soportada en esta plataforma."); // Quitado print
         // Para Windows, Web, etc., thumbnailFilePath se queda como null.
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
      // print("Error en _addVideo: $e"); // Quitado print
      if (mounted) _showSnackBar('Error al procesar video: $e');
      // Intenta limpiar si algo falló
      if (copiedVideoPath != null) await _tryDeleteFile(copiedVideoPath);
      if (thumbnailFilePath != null) await _tryDeleteFile(thumbnailFilePath);
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; _loadingMessage = ''; });
      }
    }
  }
  // ----------------------------------------------------------------

  // --- FUNCIÓN PARA ELIMINAR VIDEO (ACTUALIZADA) ---
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
        // 1. Eliminar archivo de miniatura (si existe)
        if (entry.thumbnailPath != null) {
          await _tryDeleteFile(entry.thumbnailPath!);
        }
        // 2. Eliminar archivo de video COPIADO
        await _tryDeleteFile(entry.videoPath); // entry.videoPath ahora apunta a la copia

        // 3. Eliminar la entrada de Hive
        await entry.delete();

        if (mounted) _showSnackBar('Video eliminado.');

      } catch (e) {
         // print("Error al eliminar video: $e"); // Quitado print
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

    // Si se ingresó un nombre válido y diferente
    if (newName != null && newName.isNotEmpty && newName != entry.displayName) {
      entry.displayName = newName;
      await entry.save(); // Guarda el cambio en Hive
      if(mounted) _showSnackBar('Video renombrado.');
      // El ValueListenableBuilder se encarga de actualizar la UI
    } else if (newName != null && newName.isEmpty) {
       if(mounted) _showSnackBar('El nombre no puede estar vacío.');
    }
  }
  // ------------------------------------

  // --- Navegaciones ---
  void _navigateToAnalyzer(String videoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pasamos la ruta de la COPIA al analizador
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
  // --------------------

  // --- Helper para mostrar SnackBar ---
  void _showSnackBar(String message) {
    if (!mounted) return; // Chequeo extra
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
      // print('Error al eliminar archivo $path: $e'); // Quitado print
    }
  }
  // ------------------------------------------


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Diario'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
           // --- BOTÓN PARA SELECCIONAR TAMAÑO GRID (PopupMenuButton) ---
           PopupMenuButton<int>(
              initialValue: _crossAxisCount,
              onSelected: (int newSize) {
                // Llama a la función que guarda la preferencia Y actualiza estado
                _saveGridSizePreference(newSize);
              },
              icon: Icon( // Icono cambia según selección
                _crossAxisCount == 2 ? Icons.grid_view_sharp // Menos columnas, iconos más grandes
                : _crossAxisCount == 3 ? Icons.grid_view_rounded // Medio
                : Icons.grid_4x4_rounded // Más columnas, iconos más pequeños
              ),
              tooltip: 'Tamaño de cuadrícula',
              itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                 const PopupMenuItem<int>( value: 2, child: Text('2 Columnas')),
                 const PopupMenuItem<int>( value: 3, child: Text('3 Columnas')),
                 const PopupMenuItem<int>( value: 4, child: Text('4 Columnas')),
               ],
           )
           // ----------------------------------------------------------
        ],
      ),
      // Stack para mostrar overlay de carga
      body: Stack(
        children: [
          ValueListenableBuilder<Box<VideoEntry>>(
            valueListenable: _videoBox.listenable(),
            builder: (context, box, _) {
              // Ordenamos las entradas, por ejemplo, por fecha implícita en clave?
              // O necesitaríamos un campo de fecha de creación en VideoEntry?
              // Por ahora, usamos el orden de Hive.
              final videoEntries = box.values.toList();

              if (videoEntries.isEmpty && !_isLoading) {
                return const Center( /* ... Mensaje sin videos ... */ );
              }

              // --- Cuadrícula ---
              return GridView.builder(
                key: ValueKey(_crossAxisCount), // Ayuda a Flutter a redibujar bien al cambiar tamaño
                padding: const EdgeInsets.all(12.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.8, // Mantiene proporción alto/ancho
                ),
                itemCount: videoEntries.length,
                itemBuilder: (context, index) {
                  final entry = videoEntries[index];
                  final String displayTitle = entry.displayName?.isNotEmpty == true
                     ? entry.displayName!
                     : p.basenameWithoutExtension(entry.videoPath);

                  Widget thumbnailWidget;
                  // --- Lógica Thumbnail Condicional (Android/iOS vs Otras) ---
                  if ((Platform.isAndroid || Platform.isIOS) && entry.thumbnailPath != null) {
                      final thumbFile = File(entry.thumbnailPath!);
                      // Usamos FutureBuilder para manejar existencia asíncrona del archivo
                      thumbnailWidget = FutureBuilder<bool>(
                          future: thumbFile.exists(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState != ConnectionState.done || snapshot.hasError || !snapshot.data!) {
                              return _buildPlaceholderIcon(); // Muestra placeholder si no existe o mientras carga
                            }
                            // Si existe, muestra la imagen
                            return Image.file(
                              thumbFile,
                              key: ValueKey(entry.key), // Usa la clave Hive para identificar
                              fit: BoxFit.cover,
                              frameBuilder: (context, child, frame, wasSyncLoaded) {
                                if (wasSyncLoaded || frame != null) return child;
                                return Container(color: Colors.grey[850]);
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                   color: Colors.grey[850],
                                   child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
                                );
                              },
                            );
                          }
                      );
                  } else {
                    // Para Windows, Web, o si falló la generación en Android/iOS
                    thumbnailWidget = _buildPlaceholderIcon();
                  }
                  // --------------------------------------------------------------

                  // --- GestureDetector con Menú en LongPress ---
                  return GestureDetector(
                    onTap: () => _navigateToAnalyzer(entry.videoPath), // Pasa la ruta de la COPIA
                    onLongPress: () => _showItemMenu(context, entry), // Muestra menú contextual
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: GridTile(
                        footer: GridTileBar(
                           backgroundColor: Colors.black54,
                           title: Text(
                             displayTitle, // Muestra nombre personalizado o de archivo
                             textAlign: TextAlign.center,
                             overflow: TextOverflow.ellipsis,
                             style: const TextStyle(fontSize: 10),
                           ),
                        ),
                        child: thumbnailWidget, // Muestra miniatura o placeholder
                      ),
                    ),
                  );
                  // -------------------------------------------
                },
              );
            },
          ), // Fin ValueListenableBuilder

          // --- Overlay de Carga ---
           if (_isLoading)
             Container(
               color: Colors.black.withOpacity(0.6), // Fondo semitransparente
               child: Center(
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                   decoration: BoxDecoration(
                     color: Theme.of(context).colorScheme.surface, // Usa color del tema
                     borderRadius: BorderRadius.circular(12),
                     boxShadow: [
                        BoxShadow(
                           color: Colors.black.withOpacity(0.2),
                           blurRadius: 8,
                           offset: const Offset(0, 4),
                        ),
                     ]
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
          // ------------------------
        ], // Fin Stack principal
      ),
      // --- SpeedDial (sin cambios) ---
      floatingActionButton: SpeedDial( /* ... (igual que antes) ... */ ),
    );
  } // Fin build()

  // --- Widget Auxiliar para Placeholder (sin cambios) ---
  Widget _buildPlaceholderIcon() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border.all(color: Colors.grey[700]!, width: 0.5),
      ),
      child: Icon(
        Icons.videocam_off_outlined,
        color: Colors.white38,
        size: 40,
      ),
    );
  }
  // ----------------------------------------------------

  // --- FUNCIÓN PARA MOSTRAR MENÚ CONTEXTUAL ---
  void _showItemMenu(BuildContext context, VideoEntry entry) {
    // Obtenemos el RenderBox del elemento presionado para posicionar el menú
    // Esto requiere envolver el GestureDetector en un Builder o usar GlobalKey,
    // por simplicidad, lo posicionaremos genéricamente cerca del centro.
    // Una implementación más precisa requeriría pasar el `TapDownDetails` del long press.
    final position = RelativeRect.fromLTRB(100, 200, 100, 200); // Posición genérica

    showMenu<String>(
      context: context,
      position: position, // Usa la posición calculada (o la genérica)
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'rename',
          child: const ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Renombrar'),
            dense: true, // Más compacto
          ),
        ),
        const PopupMenuDivider(), // Separador
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
    ).then<void>((String? value) {
      if (value == null) return;
      if (value == 'rename') {
        _renameVideo(entry);
      } else if (value == 'delete') {
        _deleteVideo(entry);
      }
    });
  }
  // ------------------------------------------

} // Fin _GalleryScreenState