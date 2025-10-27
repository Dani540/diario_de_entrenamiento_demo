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
  bool _showSpeedControl = false;
  bool _showTagSelector = false;
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
      if (mounted) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      }
    }).catchError((error) {
      print("Error al inicializar video: $error");
      _handleLoadError(errorMessage: 'Error al cargar el video: ${error.toString()}');
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
      _selectedTrickToAdd = _availableTricks.isNotEmpty ? _availableTricks.first : null;
    });
  }

  Future<void> _addSelectedTag() async {
    if (_selectedTrickToAdd == null) return;

    final videoProvider = context.read<VideoProvider>();
    final success = await videoProvider.addTag(widget.video.id, _selectedTrickToAdd!);

    if (mounted) {
      if (success) {
        _updateAvailableTricks();
        setState(() {
          _showTagSelector = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tag añadido'), duration: Duration(seconds: 1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(videoProvider.errorMessage ?? 'Error al añadir tag')),
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
          const SnackBar(content: Text('Tag eliminado'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  void _togglePlayPause() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _setPlaybackSpeed(double speed) {
    if (_controller.value.isInitialized) {
      _controller.setPlaybackSpeed(speed);
      setState(() {
        _currentPlaybackSpeed = speed;
        _showSpeedControl = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          final currentVideo = videoProvider.getVideoById(widget.video.id) ?? widget.video;

          return SafeArea(
            child: Stack(
              children: [
                // VIDEO CENTRADO
                Center(
                  child: FutureBuilder(
                    future: _initializeVideoPlayerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          _controller.value.isInitialized) {
                        return AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        );
                      } else if (snapshot.hasError) {
                        return const Center(
                          child: Icon(Icons.error_outline, color: Colors.red, size: 64),
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),

                // BOTÓN CERRAR (Top Left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // BOTÓN AÑADIR TAG (Top Right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedOpacity(
                    opacity: _showTagSelector ? 1.0 : 0.6,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Icon(
                        _showTagSelector ? Icons.label : Icons.label_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _showTagSelector = !_showTagSelector;
                        });
                      },
                    ),
                  ),
                ),

                // SELECTOR DE TAGS (Slide desde arriba)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  top: _showTagSelector ? 60 : -200,
                  right: 16,
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Añadir movimiento',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTrickToAdd,
                            isExpanded: true,
                            dropdownColor: Colors.grey[900],
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            items: _availableTricks.map((trick) {
                              return DropdownMenuItem(value: trick, child: Text(trick));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTrickToAdd = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _addSelectedTag,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Añadir', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // TAGS SOBRE EL VIDEO (Bottom, encima de controles)
                if (currentVideo.tags.isNotEmpty)
                  Positioned(
                    bottom: 100,
                    left: 16,
                    right: 16,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: currentVideo.tags.map((tag) {
                        return Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 11)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => _removeTag(tag),
                          backgroundColor: Colors.black.withOpacity(0.6),
                          labelStyle: const TextStyle(color: Colors.white),
                          deleteIconColor: Colors.white70,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),

                // CONTROLES DE VIDEO (Bottom)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress Bar
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          colors: VideoProgressColors(
                            playedColor: Theme.of(context).colorScheme.primary,
                            bufferedColor: Colors.white30,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Controls Row
                        Row(
                          children: [
                            // Play/Pause
                            IconButton(
                              icon: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                                size: 36,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                            const SizedBox(width: 8),
                            
                            // Time
                            ValueListenableBuilder(
                              valueListenable: _controller,
                              builder: (context, VideoPlayerValue value, child) {
                                return Text(
                                  '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                );
                              },
                            ),
                            
                            const Spacer(),
                            
                            // Speed Button
                            AnimatedOpacity(
                              opacity: _showSpeedControl ? 1.0 : 0.5,
                              duration: const Duration(milliseconds: 200),
                              child: IconButton(
                                icon: Text(
                                  '${_currentPlaybackSpeed}x',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showSpeedControl = !_showSpeedControl;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        // Speed Slider (aparece/desaparece)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _showSpeedControl
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: _SpeedSlider(
                                    currentSpeed: _currentPlaybackSpeed,
                                    onSpeedChanged: _setPlaybackSpeed,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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

// Widget personalizado para el slider de velocidad
class _SpeedSlider extends StatefulWidget {
  final double currentSpeed;
  final Function(double) onSpeedChanged;

  const _SpeedSlider({
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  @override
  State<_SpeedSlider> createState() => _SpeedSliderState();
}

class _SpeedSliderState extends State<_SpeedSlider> {
  late double _tempSpeed;

  @override
  void initState() {
    super.initState();
    _tempSpeed = widget.currentSpeed;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Text('0.25x', style: TextStyle(color: Colors.white60, fontSize: 11)),
            Expanded(
              child: Slider(
                value: _tempSpeed,
                min: 0.25,
                max: 2.0,
                divisions: 7,
                label: '${_tempSpeed}x',
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Colors.white30,
                onChanged: (value) {
                  setState(() {
                    _tempSpeed = value;
                  });
                },
                onChangeEnd: (value) {
                  widget.onSpeedChanged(value);
                },
              ),
            ),
            const Text('2.0x', style: TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        Text(
          'Desliza para ajustar',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
        ),
      ],
    );
  }
}