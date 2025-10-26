// lib/src/features/gallery/screens/gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

// Importaciones locales
import '../../video_data/models/video_entry.dart';
import '../../video_data/services/video_picker_service.dart';
import '../../video_data/repositories/video_repository.dart';
import '../widgets/video_grid_item.dart';
import '../widgets/add_video_grid_item.dart';
import '../../../core/constants.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final VideoPickerService _pickerService = VideoPickerService();
  late final VideoRepository _videoRepository;
  final Box<VideoEntry> _videoBox = Hive.box<VideoEntry>(AppConstants.videoEntriesBoxName);

  // Estado para UI
  int _crossAxisCount = AppConstants.defaultGridSize;
  bool _isLoading = false;
  String _loadingMessage = '';
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
    _loadPreferences();
  }

  Future<void> _initializeRepository() async {
    _videoRepository = VideoRepository(_videoBox);
  }

  // --- Carga/Guarda Preferencias ---
  Future<void> _loadPreferences() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || 
        Platform.isAndroid || Platform.isIOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _crossAxisCount = prefs.getInt(AppConstants.gridSizePrefKey) ?? 
              AppConstants.defaultGridSize;
          _showFab = prefs.getBool(AppConstants.showFabPrefKey) ?? true;
        });
      } catch (e) {
        _crossAxisCount = AppConstants.defaultGridSize;
        _showFab = true;
      }
    }
  }

  Future<void> _saveGridSizePreference(int count) async {
    setState(() { _crossAxisCount = count; });
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS || 
        Platform.isAndroid || Platform.isIOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(AppConstants.gridSizePrefKey, count);
      } catch (e) {
        if (mounted) _showSnackBar('Error al guardar preferencia.');
      }
    }
  }

  // --- Lógica Principal ---

  Future<void> _addVideo() async {
    final originalVideoPath = await _pickerService.pickVideoFromGallery();
    if (!mounted || originalVideoPath == null) return;

    // Verificar existencia
    if (_videoRepository.videoExists(originalVideoPath)) {
      _showSnackBar('Este video ya existe.');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Copiando video...';
    });

    try {
      // Copiar video
      await _videoRepository.addVideo(originalVideoPath: originalVideoPath);

      if (mounted) _showSnackBar('Video añadido correctamente.');
    } catch (e) {
      if (mounted) _showSnackBar('Error al añadir video: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
        });
      }
    }
  }

  Future<void> _archiveVideo(VideoEntry entry) async {
    final String nameToShow = entry.displayName ?? p.basename(entry.videoPath);
    final bool? confirmArchive = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Archivar Video'),
          content: Text(
            '¿Seguro que quieres archivar "$nameToShow"? '
            'El video se ocultará pero sus datos se conservarán (según configuración).'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Archivar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmArchive == true && mounted) {
      try {
        await _videoRepository.archiveVideo(entry);
        if (mounted) _showSnackBar('Video archivado.');
      } catch (e) {
        if (mounted) _showSnackBar('Error al archivar: $e');
      }
    }
  }

  Future<void> _deleteVideoPermanently(VideoEntry entry) async {
    final String nameToShow = entry.displayName ?? p.basename(entry.videoPath);
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Eliminar Permanentemente ⚠️'),
          content: Text(
            '¿Estás ABSOLUTAMENTE SEGURO de querer eliminar "$nameToShow"?\n\n'
            'Esta acción borrará el video, la miniatura y todos sus datos '
            'asociados (incluyendo tags) de forma IRREVERSIBLE.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              child: const Text('SÍ, ELIMINAR'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && mounted) {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Eliminando permanentemente...';
      });

      try {
        await _videoRepository.deleteVideoPermanently(entry);
        if (mounted) _showSnackBar('Video eliminado permanentemente.');
      } catch (e) {
        if (mounted) _showSnackBar('Error al eliminar: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loadingMessage = '';
          });
        }
      }
    }
  }

  Future<void> _renameVideo(VideoEntry entry) async {
    final TextEditingController renameController = TextEditingController();
    renameController.text = entry.displayName ?? 
        p.basenameWithoutExtension(entry.videoPath);

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
      try {
        await _videoRepository.renameVideo(entry, newName);
        if (mounted) _showSnackBar('Video renombrado.');
      } catch (e) {
        if (mounted) _showSnackBar('Error al renombrar: $e');
      }
    } else if (newName != null && newName.isEmpty) {
      if (mounted) _showSnackBar('El nombre no puede estar vacío.');
    }
  }

  // --- Helpers ---
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: AppConstants.snackBarDuration,
      ),
    );
  }

  // --- Menú Contextual ---
  void _showItemMenu(BuildContext itemContext, VideoEntry entry, Offset tapPosition) {
    final RenderBox overlay = Overlay.of(itemContext).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: itemContext,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Renombrar'),
            dense: true,
          ),
        ),
        PopupMenuItem<String>(
          value: 'archive',
          child: ListTile(
            leading: Icon(Icons.archive_outlined, color: Colors.orange[300]),
            title: Text('Archivar', style: TextStyle(color: Colors.orange[300])),
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete_permanently',
          child: ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Colors.red[400]),
            title: Text(
              'Eliminar Permanentemente',
              style: TextStyle(color: Colors.red[400]),
            ),
            dense: true,
          ),
        ),
      ],
      elevation: 8.0,
    ).then<void>((String? value) {
      if (value == null) return;
      if (value == 'rename') {
        _renameVideo(entry);
      } else if (value == 'archive') {
        _archiveVideo(entry);
      } else if (value == 'delete_permanently') {
        _deleteVideoPermanently(entry);
      }
    });
  }

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
              const PopupMenuItem<int>(value: 2, child: Text('2 Columnas')),
              const PopupMenuItem<int>(value: 3, child: Text('3 Columnas')),
              const PopupMenuItem<int>(value: 4, child: Text('4 Columnas')),
            ],
          )
        ],
      ),
      body: Stack(
        children: [
          ValueListenableBuilder<Box<VideoEntry>>(
            valueListenable: _videoBox.listenable(),
            builder: (context, box, _) {
              final videoEntries = _videoRepository.getActiveVideos();
              final int itemCount = videoEntries.length + 1;

              if (itemCount == 1 && !_isLoading) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AddVideoGridItem(onTap: _addVideo),
                    ),
                  ),
                );
              }

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
                  if (index == videoEntries.length) {
                    return AddVideoGridItem(onTap: _addVideo);
                  }

                  final entry = videoEntries[index];
                  return Builder(
                    builder: (itemContext) {
                      return VideoGridItem(
                        entry: entry,
                        onLongPress: (ctx, videoEntry, position) =>
                            _showItemMenu(ctx, videoEntry, position),
                      );
                    },
                  );
                },
              );
            },
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: kElevationToShadow[4],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _loadingMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Visibility(
        visible: _showFab,
        child: FloatingActionButton(
          onPressed: _addVideo,
          tooltip: 'Añadir Video',
          child: const Icon(Icons.add_to_photos_outlined),
        ),
      ),
    );
  }
}