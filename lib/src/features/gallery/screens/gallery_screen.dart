// lib/src/features/gallery/screens/gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

// Importaciones locales
import '../../video_data/models/video_entry.dart';
import '../../video_data/services/video_picker_service.dart';
// import '../../analyzer/screens/analyzer_screen.dart'; // No necesario directamente
// import '../../instructor/screens/instructor_screen.dart'; // No necesario directamente
import '../widgets/video_grid_item.dart';
import '../widgets/add_video_grid_item.dart';
import '../../settings/screens/settings_screen.dart'; // Para la clave keepArchivedTagsPrefKey

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final VideoPickerService _pickerService = VideoPickerService();
  final Box<VideoEntry> _videoBox = Hive.box<VideoEntry>('videoEntriesBox');

  // Estado para UI
  int _crossAxisCount = 3;
  bool _isLoading = false;
  String _loadingMessage = '';
  bool _showFab = true;

  // Claves para SharedPreferences
  static const String _gridSizePrefKey = 'gallery_grid_size';
  static const String _showFabPrefKey = 'show_gallery_fab';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // --- Carga/Guarda Preferencias (Sin cambios) ---
  Future<void> _loadPreferences() async {
     if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || Platform.isAndroid || Platform.isIOS) {
       try {
         final prefs = await SharedPreferences.getInstance();
         setState(() {
           _crossAxisCount = prefs.getInt(_gridSizePrefKey) ?? 3;
           _showFab = prefs.getBool(_showFabPrefKey) ?? true;
         });
       } catch (e) { _crossAxisCount = 3; _showFab = true; }
    } else { _crossAxisCount = 3; _showFab = true; }
  }
  Future<void> _saveGridSizePreference(int count) async {
     setState(() { _crossAxisCount = count; });
     if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || Platform.isAndroid || Platform.isIOS) {
       try {
         final prefs = await SharedPreferences.getInstance();
         await prefs.setInt(_gridSizePrefKey, count);
       } catch (e) { if (mounted) _showSnackBar('Error al guardar preferencia.'); }
     }
  }
  // ---------------------------------------------

  // --- Lógica Principal ---

  // _addVideo: Sin cambios funcionales respecto a la versión anterior
  Future<void> _addVideo() async {
    final originalVideoPath = await _pickerService.pickVideoFromGallery();
    if (!mounted || originalVideoPath == null) { /* ... manejo error ... */ return; }
    bool exists = _videoBox.values.any((entry) => p.basename(entry.videoPath) == p.basename(originalVideoPath) || entry.videoPath == originalVideoPath);
    if (exists) { _showSnackBar('Este video ya existe.'); return; }
    setState(() { _isLoading = true; _loadingMessage = 'Copiando video...'; });
    String? copiedVideoPath; String? thumbnailFilePath;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory(p.join(docDir.path, 'videos'));
      if (!await videosDir.exists()) { await videosDir.create(recursive: true); }
      final String fileExtension = p.extension(originalVideoPath);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String uniqueFileName = 'video_$timestamp$fileExtension';
      copiedVideoPath = p.join(videosDir.path, uniqueFileName);
      await File(originalVideoPath).copy(copiedVideoPath);

      thumbnailFilePath = null;
      if (Platform.isAndroid || Platform.isIOS) {
        setState(() { _loadingMessage = 'Generando miniatura...'; });
        try {
           final supportDir = await getApplicationSupportDirectory();
           final thumbDir = Directory(p.join(supportDir.path, 'thumbnails'));
           if (!await thumbDir.exists()) { await thumbDir.create(recursive: true); }
           thumbnailFilePath = await VideoThumbnail.thumbnailFile(
             video: copiedVideoPath, thumbnailPath: thumbDir.path, imageFormat: ImageFormat.JPEG, maxWidth: 200, quality: 80,
           );
        } catch (thumbError) { if (mounted) _showSnackBar('No se pudo generar miniatura.'); thumbnailFilePath = null; }
      }
      final newEntry = VideoEntry( videoPath: copiedVideoPath, thumbnailPath: thumbnailFilePath, displayName: p.basenameWithoutExtension(originalVideoPath), );
      await _videoBox.add(newEntry);
      if (mounted) _showSnackBar('Video añadido.');
    } catch (e) {
      if (mounted) _showSnackBar('Error al añadir video: $e');
      if (copiedVideoPath != null) await _tryDeleteFile(copiedVideoPath);
      if (thumbnailFilePath != null) await _tryDeleteFile(thumbnailFilePath);
    } finally {
      if (mounted) setState(() { _isLoading = false; _loadingMessage = ''; });
    }
  }

  // _archiveVideo: Sin cambios funcionales respecto a la versión anterior
  Future<void> _archiveVideo(VideoEntry entry) async {
     final String nameToShow = entry.displayName ?? p.basename(entry.videoPath);
    final bool? confirmArchive = await showDialog<bool>( context: context, builder: (BuildContext context) { return AlertDialog( title: const Text('Archivar Video'), content: Text('¿Seguro que quieres archivar "$nameToShow"? El video se ocultará pero sus datos se conservarán (según configuración).'), actions: <Widget>[ TextButton( child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop(false), ), TextButton( child: const Text('Archivar'), onPressed: () => Navigator.of(context).pop(true), ), ], ); }, );
    if (confirmArchive == true && mounted) {
      try {
        entry.isArchived = true;
        await entry.save();
        if (mounted) _showSnackBar('Video archivado.');
      } catch (e) { if (mounted) _showSnackBar('Error al archivar: $e'); }
    }
  }

  // *** NUEVA FUNCIÓN: Eliminar Permanentemente ***
  Future<void> _deleteVideoPermanently(VideoEntry entry) async {
    final String nameToShow = entry.displayName ?? p.basename(entry.videoPath);
    // Diálogo de confirmación MÁS FUERTE
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Eliminar Permanentemente ⚠️'),
          content: Text('¿Estás ABSOLUTAMENTE SEGURO de querer eliminar "$nameToShow"?\n\nEsta acción borrará el video, la miniatura y todos sus datos asociados (incluyendo tags) de forma IRREVERSIBLE.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            // Botón de confirmación más destacado y peligroso
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              child: const Text('SÍ, ELIMINAR'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    // Si el usuario confirma la eliminación permanente
    if (confirmDelete == true && mounted) {
      setState(() { _isLoading = true; _loadingMessage = 'Eliminando permanentemente...'; });
      try {
        // 1. Eliminar archivo de miniatura (si existe)
        if (entry.thumbnailPath != null) {
          await _tryDeleteFile(entry.thumbnailPath!);
        }
        // 2. Eliminar archivo de video COPIADO
        await _tryDeleteFile(entry.videoPath);

        // 3. Eliminar la entrada de Hive COMPLETAMENTE
        await entry.delete(); // Borra el objeto de la base de datos

        if (mounted) _showSnackBar('Video eliminado permanentemente.');

      } catch (e) {
        if (mounted) _showSnackBar('Error al eliminar permanentemente: $e');
      } finally {
         if (mounted) setState(() { _isLoading = false; _loadingMessage = ''; });
      }
      // El ValueListenableBuilder actualizará la UI
    }
  }
  // ********************************************

  // _renameVideo: Sin cambios funcionales
  Future<void> _renameVideo(VideoEntry entry) async {
    final TextEditingController renameController = TextEditingController();
    renameController.text = entry.displayName ?? p.basenameWithoutExtension(entry.videoPath);
    final String? newName = await showDialog<String>( context: context, builder: (context) => AlertDialog( title: const Text('Renombrar Clip'), content: TextField( controller: renameController, autofocus: true, decoration: const InputDecoration(hintText: 'Nuevo nombre'), onSubmitted: (value) => Navigator.of(context).pop(value.trim()), ), actions: [ TextButton( child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop(), ), TextButton( child: const Text('Guardar'), onPressed: () => Navigator.of(context).pop(renameController.text.trim()), ), ], ), );
    if (newName != null && newName.isNotEmpty && newName != entry.displayName) {
      entry.displayName = newName; await entry.save(); if(mounted) _showSnackBar('Video renombrado.');
    } else if (newName != null && newName.isEmpty) { if(mounted) _showSnackBar('El nombre no puede estar vacío.'); }
  }
  // --------------------------------------------------------------------------------------


  // --- Helpers (sin cambios) ---
  void _showSnackBar(String message) {
     if (!mounted) return;
     ScaffoldMessenger.of(context).removeCurrentSnackBar();
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
     );
  }
  Future<void> _tryDeleteFile(String path) async {
     try { final file = File(path); if (await file.exists()) { await file.delete(); } } catch (e) { /* Error silencioso */ }
  }
  // -----------------------------

  // --- Menú Contextual (ACTUALIZADO CON OPCIÓN ELIMINAR PERMANENTE) ---
  void _showItemMenu(BuildContext itemContext, VideoEntry entry, Offset tapPosition) {
    final RenderBox overlay = Overlay.of(itemContext).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: itemContext,
      position: RelativeRect.fromRect( Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 1, 1), Offset.zero & overlay.size ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'rename',
          child: const ListTile( leading: Icon(Icons.edit_outlined), title: Text('Renombrar'), dense: true, )
        ),
        PopupMenuItem<String>(
          value: 'archive',
          child: ListTile( leading: Icon(Icons.archive_outlined, color: Colors.orange[300]), title: Text('Archivar', style: TextStyle(color: Colors.orange[300])), dense: true, )
        ),
        const PopupMenuDivider(), // Separador visual
        // *** NUEVA OPCIÓN ***
        PopupMenuItem<String>(
          value: 'delete_permanently', // Nuevo valor
          child: ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Colors.red[400]),
            title: Text('Eliminar Permanentemente', style: TextStyle(color: Colors.red[400])),
            dense: true,
          ),
        ),
        // *******************
      ],
      elevation: 8.0,
    ).then<void>((String? value) {
      if (value == null) return; // Si no se selecciona nada
      if (value == 'rename') {
        _renameVideo(entry);
      } else if (value == 'archive') {
        _archiveVideo(entry);
      } else if (value == 'delete_permanently') { // Maneja el nuevo valor
        _deleteVideoPermanently(entry); // Llama a la nueva función
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
              onSelected: _saveGridSizePreference,
              icon: Icon(
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
              // Filtra para mostrar solo los videos NO archivados
              final allEntries = box.values.toList();
              final videoEntries = allEntries.where((entry) => !entry.isArchived).toList();

              // +1 para la tarjeta de añadir
              final int itemCount = videoEntries.length + 1;

              // Mensaje central si no hay videos (y no está cargando)
              if (itemCount == 1 && !_isLoading) {
                 return Center(
                   child: Padding(
                     padding: const EdgeInsets.all(40.0),
                     child: AspectRatio(
                       aspectRatio: 1,
                       child: AddVideoGridItem(onTap: _addVideo), // Tarjeta '+'
                     ),
                   ),
                 );
              }

              // --- GridView Refactorizado con Tarjeta Añadir ---
              return GridView.builder(
                key: ValueKey('grid_$_crossAxisCount'),
                padding: const EdgeInsets.all(12.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.8,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  // Si es el último item, muestra la tarjeta para añadir
                  if (index == videoEntries.length) {
                    return AddVideoGridItem(onTap: _addVideo);
                  }
                  // Si no, muestra el VideoGridItem normal
                  final entry = videoEntries[index];
                  // Usa Builder para pasar el context correcto al menú
                  return Builder(
                     builder: (itemContext) {
                        return VideoGridItem(
                          entry: entry,
                          // Pasa el callback _showItemMenu
                          onLongPress: (ctx, videoEntry, position) => _showItemMenu(ctx, videoEntry, position),
                        );
                     }
                  );
                },
              );
              // ----------------------------------------------
            },
          ), // Fin ValueListenableBuilder

          // --- Overlay de Carga (sin cambios) ---
           if (_isLoading)
             Positioned.fill(
               child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration( color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), boxShadow: kElevationToShadow[4], ),
                      child: Column( mainAxisSize: MainAxisSize.min, children: [ const CircularProgressIndicator(), const SizedBox(height: 16), Text( _loadingMessage, style: TextStyle(color: Theme.of(context).colorScheme.onSurface), textAlign: TextAlign.center, ), ], ),
                    ),
                  ),
                ),
             ),
          // -------------------------------------
        ], // Fin Stack principal
      ),
      // --- FAB Opcional (Ahora es un FAB simple) ---
      floatingActionButton: Visibility(
        visible: _showFab, // Controlado por la preferencia
        child: FloatingActionButton(
          onPressed: _addVideo, // Acción simple de añadir
          tooltip: 'Añadir Video',
          child: const Icon(Icons.add_to_photos_outlined), // Icono diferente
        ),
      ),
      // ------------------------------------------
    );
  } // Fin build()

} // Fin _GalleryScreenState