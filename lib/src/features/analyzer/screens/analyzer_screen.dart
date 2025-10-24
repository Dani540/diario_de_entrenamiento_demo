import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Asegúrate que las rutas coincidan con tu estructura
import '../../video_data/models/trick_list.dart'; // Importa la lista de movimientos
import '../../video_data/models/video_entry.dart';

class AnalyzerScreen extends StatefulWidget {
  final String videoPath;

  const AnalyzerScreen({super.key, required this.videoPath});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  VideoEntry? _currentVideoEntry;
  List<String> _tags = []; // Lista local con los tags del video actual
  double _currentPlaybackSpeed = 1.0;
  bool _showControls = true;
  String? _selectedTrickToAdd; // Variable para guardar la selección del Dropdown

  // Lista de movimientos disponibles para añadir (excluyendo los ya añadidos)
  List<String> _availableTricks = [];

  @override
  void initState() {
    super.initState();
    _loadVideoEntryAndSetup(); // Carga datos y configura estado inicial
  }

  void _loadVideoEntryAndSetup() {
    final box = Hive.box<VideoEntry>('videoEntriesBox');
    try {
      _currentVideoEntry = box.values.firstWhere(
        (entry) => entry.videoPath == widget.videoPath,
      );
      // Sincroniza la lista local _tags
      _tags = List<String>.from(_currentVideoEntry!.tags);
      // Prepara la lista de trucos disponibles para el dropdown
      _updateAvailableTricks();
      // Inicializa el video DESPUÉS de cargar la entrada
      _initializeVideo();
    } catch (e) {
      print(
          "Error: No se encontró VideoEntry para ${widget.videoPath}. Error: $e");
      _handleLoadError();
    }
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.file(File(widget.videoPath));
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      if (mounted) setState(() {});
      _controller.setLooping(true);
    }).catchError((error) {
      print("Error al inicializar video: $error");
      _handleLoadError(errorMessage: 'Error al cargar el video: ${error.toString()}');
    });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }


  void _handleLoadError({String errorMessage = 'Error: No se encontró la información del video.'}) {
     WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(errorMessage)),
         );
         Navigator.of(context).pop();
       }
     });
  }


  // Actualiza la lista de trucos disponibles para el Dropdown
  void _updateAvailableTricks() {
    final allTricks = TrickingMoves.getAllMoves();
    setState(() {
      _availableTricks = allTricks.where((trick) => !_tags.contains(trick)).toList();
      // Ordenar alfabéticamente para facilitar la búsqueda
      _availableTricks.sort();
      _selectedTrickToAdd = null; // Resetea la selección del dropdown
    });
  }

  // --- Funciones para Tags ---
  void _addSelectedTag() {
    // Añade el tag seleccionado en el Dropdown (_selectedTrickToAdd)
    if (_selectedTrickToAdd != null && _currentVideoEntry != null) {
      if (!_tags.contains(_selectedTrickToAdd!)) {
        // No necesitamos setState para _tags aquí porque _updateAvailableTricks lo hará
        _currentVideoEntry!.addTag(_selectedTrickToAdd!); // addTag guarda en Hive y actualiza _currentVideoEntry.tags
        // Actualizamos _tags local y la lista _availableTricks
         _tags = List<String>.from(_currentVideoEntry!.tags); // Sincroniza lista local
        _updateAvailableTricks(); // Esto llamará a setState
      }
    }
  }

  void _removeTag(String tag) {
    if (_currentVideoEntry != null) {
      // No necesitamos setState para _tags aquí porque _updateAvailableTricks lo hará
      _currentVideoEntry!.removeTag(tag); // removeTag guarda en Hive
      // Actualizamos _tags local y la lista _availableTricks
      _tags = List<String>.from(_currentVideoEntry!.tags); // Sincroniza lista local
      _updateAvailableTricks(); // Esto llamará a setState
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
    final videoFileName = widget.videoPath.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: Text(videoFileName, style: const TextStyle(fontSize: 16)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // --- Zona del Video Player (sin cambios respecto a la versión anterior) ---
          Flexible(
            fit: FlexFit.loose,
            child: GestureDetector(
              onTap: _toggleControlsVisibility,
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && _controller.value.isInitialized) {
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
                       aspectRatio: 16/9,
                       child: Container(color: Colors.black, child: const Center(child: Text('Error al cargar video', style: TextStyle(color: Colors.red)))),
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
          ), // Fin Flexible video

          // --- Zona de Contenido Scrollable ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Controles de Velocidad (sin cambios) ---
                  Text('Velocidad:', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(
                      spacing: 8.0,
                      runSpacing: 0.0,
                      children: [0.25, 0.5, 1.0, 1.5, 2.0]
                          .map((speed) => _buildSpeedButton(speed))
                          .toList(),
                    ),
                  const SizedBox(height: 20),

                  // --- *** SECCIÓN DE TAGS MODIFICADA *** ---
                  Text('Etiquetas (Movimientos):', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),

                  // --- Dropdown y Botón para AÑADIR tags ---
                  Row(
                    children: [
                      Expanded(
                        // Usamos un DropdownButton para SELECCIONAR el tag
                        child: DropdownButtonHideUnderline( // Oculta la línea de abajo
                          child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                             decoration: BoxDecoration(
                               color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                               borderRadius: BorderRadius.circular(8),
                             ),
                            child: DropdownButton<String>(
                              value: _selectedTrickToAdd,
                              isExpanded: true, // Ocupa todo el ancho
                              hint: const Text('Selecciona un movimiento...'), // Placeholder
                              // Genera los items del dropdown desde la lista de disponibles
                              items: _availableTricks.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              // Actualiza la variable de estado cuando se selecciona algo
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedTrickToAdd = newValue;
                                });
                              },
                              // Estilos adicionales
                               dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                               icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).iconTheme.color),
                               style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                      // Botón para confirmar y añadir el tag seleccionado
                      IconButton(
                        icon: const Icon(Icons.add_circle), // Icono más claro para añadir
                        color: Theme.of(context).colorScheme.primary,
                        tooltip: 'Añadir Tag Seleccionado',
                        // Solo se habilita si hay algo seleccionado
                        onPressed: _selectedTrickToAdd != null ? _addSelectedTag : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- Mostrar los tags YA AÑADIDOS al video ---
                  Text('Tags añadidos:', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  _tags.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Ningún tag añadido a este video.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        )
                      : Wrap( // Muestra los chips de los tags actuales
                          spacing: 6.0,
                          runSpacing: 4.0,
                          children: _tags.map((tag) => Chip(
                            label: Text(tag),
                            labelStyle: const TextStyle(fontSize: 12),
                            onDeleted: () => _removeTag(tag), // Permite eliminar
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            deleteIconColor: Colors.redAccent.withOpacity(0.7),
                            deleteIcon: const Icon(Icons.close, size: 14),
                          )).toList(),
                        ),
                  // --- *** FIN SECCIÓN DE TAGS MODIFICADA *** ---

                  const SizedBox(height: 30), // Espacio al final
                ],
              ),
            ),
          ), // Fin Expanded contenido
        ],
      ), // Fin Column principal
    ); // Fin Scaffold
  }

  // --- Widgets Auxiliares (sin cambios) ---
  Widget _buildSpeedButton(double speed) {
    // ... (igual que antes) ...
    bool isActive = _currentPlaybackSpeed == speed;
    return ChoiceChip(
      label: Text('${speed}x'),
      labelStyle: TextStyle(fontSize: 12, color: isActive ? Theme.of(context).colorScheme.onPrimary : null),
      selected: isActive,
      onSelected: (_) => _setPlaybackSpeed(speed),
      selectedColor: Theme.of(context).colorScheme.primary, // Color cuando está activo
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, // Color de fondo normal
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      visualDensity: VisualDensity.compact,
       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildControlsOverlay() {
    // ... (igual que antes) ...
    if (!_controller.value.isInitialized) {
     return const SizedBox.shrink(); // No mostrar si no está listo
   }
    return Container(
      // Gradiente oscuro en la parte inferior para legibilidad
      decoration: BoxDecoration(
         gradient: LinearGradient(
           begin: Alignment.topCenter,
           end: Alignment.bottomCenter,
           colors: [ Colors.transparent, Colors.black.withOpacity(0.8) ],
           stops: const [0.0, 1.0], // Empieza transparente, termina oscuro
         )
      ),
      child: Column(
         mainAxisSize: MainAxisSize.min, // Ocupa solo lo necesario
         children: [
            // Barra de Progreso
            VideoProgressIndicator(
               _controller,
               allowScrubbing: true, // Permite buscar en el video
               padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
               colors: VideoProgressColors( // Colores personalizados
                  playedColor: Theme.of(context).colorScheme.primary,
                  bufferedColor: Colors.white.withOpacity(0.3),
                  backgroundColor: Colors.white.withOpacity(0.1),
               ),
            ),
            // Fila con botón Play/Pause y Tiempo
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0), // Ajusta padding
              child: Row(
                children: [
                  // Botón Play/Pause a la izquierda
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      color: Colors.white,
                      size: 36, // Tamaño del icono
                    ),
                    padding: EdgeInsets.zero, // Quita padding extra del botón
                    constraints: const BoxConstraints(), // Permite tamaño del icono
                    onPressed: _togglePlayPause,
                  ),
                  const SizedBox(width: 12), // Espacio
                  // Tiempo Actual / Duración Total
                   ValueListenableBuilder( // Escucha cambios en el controller para actualizar el tiempo
                      valueListenable: _controller,
                      builder: (context, VideoPlayerValue value, child) {
                         return Text(
                            '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, shadows: [Shadow(blurRadius: 1)]),
                         );
                      },
                   ),
                   const Spacer(), // Empuja los siguientes elementos a la derecha (si los hubiera)
                ],
              ),
            ),
         ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    // ... (igual que antes) ...
    if (duration == Duration.zero) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
} // Fin _AnalyzerScreenState