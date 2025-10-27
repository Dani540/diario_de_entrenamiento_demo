// lib/src/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import '../../domain/entities/video.dart';
import '../../presentation/providers/video_provider.dart';
import '../../presentation/widgets/video_grid_item.dart';
import '../../presentation/widgets/add_video_grid_item.dart';
import '../../../../core/constants.dart';
import '../../../video_picker/video_picker_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final VideoPickerService _pickerService = VideoPickerService();
  late TabController _tabController;
  
  int _crossAxisCount = AppConstants.defaultGridSize;
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPreferences();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().loadVideos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    setState(() {
      _crossAxisCount = count;
    });
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

  Future<void> _addVideo() async {
    final originalVideoPath = await _pickerService.pickVideoFromGallery();
    if (!mounted || originalVideoPath == null) return;

    final videoProvider = context.read<VideoProvider>();
    final success = await videoProvider.addNewVideo(originalVideoPath);

    if (mounted) {
      if (success) {
        _showSnackBar('Video añadido correctamente.');
      } else {
        _showSnackBar(videoProvider.errorMessage ?? 'Error al añadir video.');
      }
    }
  }

  Future<void> _archiveVideo(Video video) async {
    final String nameToShow = video.displayName ?? p.basename(video.videoPath);
    final bool? confirmArchive = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Archivar Video'),
          content: Text(
            '¿Seguro que quieres archivar "$nameToShow"? '
            'El video se ocultará pero sus datos se conservarán.',
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
      final videoProvider = context.read<VideoProvider>();
      final success = await videoProvider.archiveVideoById(video.id);

      if (mounted) {
        _showSnackBar(success ? 'Video archivado.' : 'Error al archivar video.');
      }
    }
  }

  Future<void> _deleteVideoPermanently(Video video) async {
    final String nameToShow = video.displayName ?? p.basename(video.videoPath);
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Eliminar Permanentemente ⚠️'),
          content: Text(
            '¿Estás ABSOLUTAMENTE SEGURO de querer eliminar "$nameToShow"?\n\n'
            'Esta acción borrará el video, la miniatura y todos sus datos '
            'asociados (incluyendo tags) de forma IRREVERSIBLE.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
              ),
              child: const Text('SÍ, ELIMINAR'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && mounted) {
      final videoProvider = context.read<VideoProvider>();
      final success = await videoProvider.deleteVideoById(video.id);

      if (mounted) {
        _showSnackBar(
          success ? 'Video eliminado permanentemente.' : 'Error al eliminar video.',
        );
      }
    }
  }

  Future<void> _renameVideo(Video video) async {
    final TextEditingController renameController = TextEditingController();
    renameController.text = video.displayName ?? p.basenameWithoutExtension(video.videoPath);

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

    if (newName != null && newName.isNotEmpty && newName != video.displayName) {
      final videoProvider = context.read<VideoProvider>();
      final success = await videoProvider.renameVideoById(video.id, newName);

      if (mounted) {
        _showSnackBar(success ? 'Video renombrado.' : 'Error al renombrar video.');
      }
    } else if (newName != null && newName.isEmpty) {
      if (mounted) _showSnackBar('El nombre no puede estar vacío.');
    }
  }

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

  void _showItemMenu(BuildContext itemContext, Video video, Offset tapPosition) {
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
            leading: Icon(Icons.archive_outlined, color: Colors.orange),
            title: Text('Archivar', style: TextStyle(color: Colors.orange)),
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete_permanently',
          child: ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: Text('Eliminar Permanentemente', style: TextStyle(color: Colors.red)),
            dense: true,
          ),
        ),
      ],
      elevation: 8.0,
    ).then<void>((String? value) {
      if (value == null) return;
      if (value == 'rename') {
        _renameVideo(video);
      } else if (value == 'archive') {
        _archiveVideo(video);
      } else if (value == 'delete_permanently') {
        _deleteVideoPermanently(video);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: _ProfileHeader(),
              ),
              actions: [
                PopupMenuButton<int>(
                  initialValue: _crossAxisCount,
                  onSelected: _saveGridSizePreference,
                  icon: Icon(_crossAxisCount == 2
                      ? Icons.grid_view_sharp
                      : _crossAxisCount == 3
                          ? Icons.grid_view_rounded
                          : Icons.grid_4x4_rounded),
                  tooltip: 'Tamaño de cuadrícula',
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                    const PopupMenuItem<int>(value: 2, child: Text('2 Columnas')),
                    const PopupMenuItem<int>(value: 3, child: Text('3 Columnas')),
                    const PopupMenuItem<int>(value: 4, child: Text('4 Columnas')),
                  ],
                )
              ],
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on), text: 'Videos'),
                    Tab(icon: Icon(Icons.info_outline), text: 'Info'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildVideoGrid(),
            _buildInfoTab(),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0 && _showFab
          ? FloatingActionButton(
              onPressed: _addVideo,
              tooltip: 'Añadir Video',
              child: const Icon(Icons.add_to_photos_outlined),
            )
          : null,
    );
  }

  Widget _buildVideoGrid() {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, child) {
        if (videoProvider.isLoading && videoProvider.videos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final videos = videoProvider.videos;
        final int itemCount = videos.length + 1;

        if (itemCount == 1 && !videoProvider.isLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no tienes videos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  AspectRatio(
                    aspectRatio: 1,
                    child: AddVideoGridItem(onTap: _addVideo),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(
          children: [
            GridView.builder(
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
                if (index == videos.length) {
                  return AddVideoGridItem(onTap: _addVideo);
                }

                final video = videos[index];
                return Builder(
                  builder: (itemContext) {
                    return VideoGridItem(
                      video: video,
                      onLongPress: (ctx, v, position) => _showItemMenu(ctx, v, position),
                    );
                  },
                );
              },
            ),
            if (videoProvider.isLoading)
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
                            videoProvider.loadingMessage,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, child) {
        final totalVideos = videoProvider.videos.length;
        final allTags = videoProvider.videos
            .expand((v) => v.tags)
            .toSet()
            .toList()
          ..sort();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoCard(
                icon: Icons.videocam,
                title: 'Videos Totales',
                value: totalVideos.toString(),
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.label,
                title: 'Movimientos Únicos',
                value: allTags.length.toString(),
              ),
              const SizedBox(height: 24),
              Text(
                'Movimientos Registrados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (allTags.isEmpty)
                const Text(
                  'Aún no has etiquetado movimientos.',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allTags.map((tag) {
                    final count = videoProvider?.videos.where((v) => v.tags.contains(tag)).length ?? 0;
                    return Chip(
                      label: Text('$tag ($count)'),
                      avatar: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          count.toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Header del perfil estilo Instagram
class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Mi Perfil',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tricker en progreso',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Delegado para el TabBar sticky
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

// Card de información
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}