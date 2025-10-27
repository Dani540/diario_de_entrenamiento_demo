// lib/src/features/video_management/presentation/screens/analyzer_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/video.dart';
import '../providers/video_provider.dart';
import '../../../tricks/data/models/trick_list.dart';

class AnalyzerScreen extends StatefulWidget {
  final Video video;

  const AnalyzerScreen({super.key, required this.video});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  
  double _currentPlaybackSpeed = 1.0;
  bool _showControls = true;
  String? _selectedTrickToAdd;
  List<String> _availableTricks = [];

  @override
  void initState() {
    super.initState();
    _updateAvailableTricks();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.file(File(widget.video.videoPath));
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      if (mounted) setState(() {});
      _controller.setLooping(true);
    }).catchError((error) {
      print("Error al inicializar video: $error");
      _handleLoadError(
        errorMessage: 'Error al cargar el video: ${error.toString()}',
      );
    });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _handleLoadError({String errorMessage = 'Error al cargar el video.'}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        Navigator.of(context).pop();
      }
    });
  }

  void _updateAvailableTricks() {
    final allTricks = TrickingMoves.getAllMoves();
    setState(() {
      _availableTricks = allTricks
          .where((trick) => !widget.video.tags.contains(trick))
          .toList();
      _availableTricks.sort();
      _selectedTrickToAdd = null;
    });
  }

  // --- Funciones para Tags ---
  Future<void> _addSelectedTag() async {
    if (_selectedTrickToAdd == null) return;

    final videoProvider = context.read<VideoProvider>();
    final success = await videoProvider.addTag(
      widget.video.id,
      _selectedTrickToAdd!,
    );

    if (mounted) {
      if (success) {
        _updateAvailableTricks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag añadido')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              videoProvider.errorMessage ?? 'Error al añadir tag',
            ),
          ),
        );
      }
    }
  }

  Future<void> _removeTag(String tag) async {
    final videoProvider = context.read<VideoProvider>();
    final success = await videoProvider.removeTag(widget.video.id, tag);

    if (mounted) {
      if (success) {
        _updateAvailableTricks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag eliminado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              videoProvider.errorMessage ?? 'Error al eliminar tag',
            ),
          ),
        );
      }
    }
  }

  // --- Funciones para Controles de Video ---
  void _togglePlayPause() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _setPlaybackSpeed(double speed) {
    if (_controller.value.isInitialized) {
      _controller.setPlaybackSpeed(speed);
      setState(() => _currentPlaybackSpeed = speed);
    }
  }

  void _toggleControlsVisibility() {
    setState(() => _showControls = !_showControls);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, child) {
        // Obtener la versión actualizada del video
        final currentVideo = videoProvider.getVideoById(widget.video.id) ?? 
            widget.video;
        
        final videoFileName = currentVideo.displayName ?? 
            currentVideo.videoPath.split('/').last;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              videoFileName,
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Column(
            children: [
              // --- Zona del Video Player ---
              Flexible(
                fit: FlexFit.loose,
                child: GestureDetector(
                  onTap: _toggleControlsVisibility,
                  child: FutureBuilder(
                    future: _initializeVideoPlayerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          _controller.value.isInitialized) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                          ),
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: <Widget>[
                                VideoPlayer(_controller),
                                AnimatedOpacity(
                                  opacity: _showControls ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: _buildControlsOverlay(),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            color: Colors.black,
                            child: const Center(
                              child: Text(
                                'Error al cargar video',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return const AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                    },
                  ),
                ),
              ),

              // --- Zona de Contenido Scrollable ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Controles de Velocidad ---
                      Text(
                        'Velocidad:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 0.0,
                        children: [0.25, 0.5, 1.0, 1.5, 2.0]
                            .map((speed) => _buildSpeedButton(speed))
                            .toList(),
                      ),
                      const SizedBox(height: 20),

                      // --- Sección de Tags ---
                      Text(
                        'Etiquetas (Movimientos):',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),

                      // Dropdown y Botón para añadir tags
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withAlpha((255 * 0.5).round()),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedTrickToAdd,
                                  isExpanded: true,
                                  hint: const Text('Selecciona un movimiento...'),
                                  items: _availableTricks
                                      .map<DropdownMenuItem<String>>(
                                    (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      );
                                    },
                                  ).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedTrickToAdd = newValue;
                                    });
                                  },
                                  dropdownColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            color: Theme.of(context).colorScheme.primary,
                            tooltip: 'Añadir Tag Seleccionado',
                            onPressed: _selectedTrickToAdd != null
                                ? _addSelectedTag
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Mostrar los tags ya añadidos
                      Text(
                        'Tags añadidos:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      currentVideo.tags.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Ningún tag añadido a este video.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : Wrap(
                              spacing: 6.0,
                              runSpacing: 4.0,
                              children: currentVideo.tags
                                  .map(
                                    (tag) => Chip(
                                      label: Text(tag),
                                      labelStyle: const TextStyle(fontSize: 12),
                                      onDeleted: () => _removeTag(tag),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 0,
                                      ),
                                      deleteIconColor: Colors.redAccent
                                          .withAlpha((255 * 0.7).round()),
                                      deleteIcon:
                                          const Icon(Icons.close, size: 14),
                                    ),
                                  )
                                  .toList(),
                            ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeedButton(double speed) {
    bool isActive = _currentPlaybackSpeed == speed;
    return ChoiceChip(
      label: Text('${speed}x'),
      labelStyle: TextStyle(
        fontSize: 12,
        color: isActive ? Theme.of(context).colorScheme.onPrimary : null,
      ),
      selected: isActive,
      onSelected: (_) => _setPlaybackSpeed(speed),
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildControlsOverlay() {
    if (!_controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withAlpha((255 * 0.8).round())
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            colors: VideoProgressColors(
              playedColor: Theme.of(context).colorScheme.primary,
              bufferedColor: Colors.white.withAlpha((255 * 0.3).round()),
              backgroundColor: Colors.white.withAlpha((255 * 0.1).round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: Colors.white,
                    size: 36,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _togglePlayPause,
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, VideoPlayerValue value, child) {
                    return Text(
                      '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        shadows: [Shadow(blurRadius: 1)],
                      ),
                    );
                  },
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}