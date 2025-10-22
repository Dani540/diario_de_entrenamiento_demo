import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:video_player/video_player.dart';
// Asegúrate que las rutas de importación coincidan con tu estructura
import '../../video_data/models/video_entry.dart';
import '../../video_data/services/database_service.dart';

class AnalyzerScreen extends StatefulWidget {
  final String videoPath;

  const AnalyzerScreen({super.key, required this.videoPath});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  final TextEditingController _tagController = TextEditingController();
  // No necesitamos instanciar DatabaseService si usamos métodos estáticos o accedemos directo a Hive
  VideoEntry? _currentVideoEntry;
  List<String> _tags = [];
  double _currentPlaybackSpeed = 1.0;
  bool _showControls = true; // Para mostrar/ocultar controles

  @override
  void initState() {
    super.initState();
    _loadVideoEntry(); // Carga la entrada de la DB ANTES de inicializar el video

    // Inicializa el controlador de video
    // Usamos Uri.file para mejor compatibilidad entre plataformas
    _controller = VideoPlayerController.file(File(widget.videoPath));

    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      // Forzamos el redibujo para que se muestre el primer frame
      if (mounted) setState(() {});
      _controller.setLooping(true);
      // _controller.play(); // Quizás no queremos que empiece solo
    }).catchError((error) {
      // Manejo básico de errores si el video no carga
       print("Error al inicializar video: $error");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error al cargar el video: $error')),
         );
       }
    });

    // Listener para actualizar estado de reproducción
    _controller.addListener(() {
      if (mounted) setState(() {}); // Actualiza la UI (ej: botón play/pause)
    });
  }

  // Carga la entrada de VideoEntry desde Hive buscando por 'videoPath'
  void _loadVideoEntry() {
    final box = Hive.box<VideoEntry>('videoEntriesBox');
    // Iteramos para encontrar la entrada correcta, ya que Hive no busca por campo
    for (var entry in box.values) {
      if (entry.videoPath == widget.videoPath) {
        _currentVideoEntry = entry;
        _tags = List<String>.from(entry.tags); // Copiamos los tags a la lista local
        break; // Salimos del bucle una vez encontrado
      }
    }

    if (_currentVideoEntry == null) {
      print("Error: No se encontró VideoEntry para ${widget.videoPath}");
      // Considera mostrar un mensaje al usuario o volver atrás
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Error: No se encontró la información del video.')),
             );
             Navigator.of(context).pop(); // Vuelve a la pantalla anterior
         }
      });
    }
  }

  // --- Funciones para Tags ---
  void _addTag() {
    final String tag = _tagController.text.trim().toLowerCase(); // Guardar en minúsculas?
    if (tag.isNotEmpty && _currentVideoEntry != null) {
      if (!_tags.contains(tag)) {
        setState(() => _tags.add(tag));
        _currentVideoEntry!.addTag(tag); // El método addTag ya llama a save()
        _tagController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El tag "$tag" ya existe.'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  void _removeTag(String tag) {
    if (_currentVideoEntry != null) {
      setState(() => _tags.remove(tag));
      _currentVideoEntry!.removeTag(tag); // removeTag llama a save()
    }
  }

  // --- Funciones para Controles de Video ---
  void _togglePlayPause() {
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

  // Para mostrar/ocultar controles al tocar el video
  void _toggleControlsVisibility() {
    setState(() => _showControls = !_showControls);
  }


  @override
  void dispose() {
    _controller.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Extraer nombre del archivo para el título
    final videoFileName = widget.videoPath.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: Text(videoFileName, style: const TextStyle(fontSize: 16)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column( // Mantiene la división entre video y el resto
        children: [
          // --- Zona del Video Player ---
          // (Esta parte con GestureDetector, FutureBuilder, AspectRatio, Stack se queda igual)
          GestureDetector(
             onTap: _toggleControlsVisibility,
            child: FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                // ... (el código del FutureBuilder se mantiene igual que antes) ...
                 if (snapshot.connectionState == ConnectionState.done && _controller.value.isInitialized) {
                  return AspectRatio(
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
                  );
                } else if (snapshot.hasError) {
                   return AspectRatio(
                     aspectRatio: 16/9,
                     child: Container(
                       color: Colors.black,
                       child: const Center(
                         child: Text('Error al cargar video', style: TextStyle(color: Colors.red))
                       ),
                     ),
                   );
                }
                else {
                  return const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            ),
          ),

          // --- Zona de Contenido Scrollable ---
          Expanded( // Hace que esta parte ocupe el espacio restante
            child: SingleChildScrollView( // ¡LA CLAVE! Permite scroll si el contenido se desborda
              padding: const EdgeInsets.all(16.0),
              child: Column( // Colocamos el contenido original del ListView aquí
                crossAxisAlignment: CrossAxisAlignment.start, // Alinea textos a la izquierda
                children: [
                  // --- Controles de Velocidad ---
                   Text('Velocidad:', style: Theme.of(context).textTheme.titleSmall),
                   const SizedBox(height: 4),
                   Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0, // Espacio si van a nueva línea
                      children: [0.25, 0.5, 1.0, 1.5, 2.0]
                          .map((speed) => _buildSpeedButton(speed))
                          .toList(),
                    ),
                   const SizedBox(height: 24), // Más espacio

                  // --- Zona de Tags ---
                  Text('Etiquetas (Movimientos):', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    // ... (El Row con TextField e IconButton se mantiene igual) ...
                     children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: 'Añadir tag...',
                            isDense: true, // Más compacto
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline), // Icono más claro
                        onPressed: _addTag,
                        tooltip: 'Añadir Tag',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Mostrar tags existentes
                   if (_tags.isEmpty)
                     const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No hay tags añadidos.', style: TextStyle(color: Colors.grey)),
                     )
                   else
                     Wrap(
                       spacing: 6.0,
                       runSpacing: 0.0,
                       children: _tags.map((tag) => Chip(
                         label: Text(tag),
                         onDeleted: () => _removeTag(tag),
                         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                         padding: const EdgeInsets.symmetric(horizontal: 4),
                          deleteIconColor: Colors.redAccent.withOpacity(0.7),
                       )).toList(),
                     ),

                  // Espacio al final para que el scroll se vea mejor
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets Auxiliares ---

  // Botón para control de velocidad
  Widget _buildSpeedButton(double speed) {
    bool isActive = _currentPlaybackSpeed == speed;
    return ChoiceChip(
      label: Text('${speed}x'),
      selected: isActive,
      onSelected: (_) => _setPlaybackSpeed(speed),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      labelPadding: EdgeInsets.symmetric(horizontal: 4),
       visualDensity: VisualDensity.compact, // Más compacto
    );
  }

  // Overlay de controles sobre el video
  Widget _buildControlsOverlay() {
   if (!_controller.value.isInitialized) {
     return const SizedBox.shrink(); // No mostrar si no está inicializado
   }
    return Container(
      // Fondo semitransparente
      decoration: BoxDecoration(
         gradient: LinearGradient(
           begin: Alignment.topCenter,
           end: Alignment.bottomCenter,
           colors: [
             Colors.transparent,
             Colors.black.withOpacity(0.6),
             Colors.black.withOpacity(0.8),
           ],
           stops: const [0.0, 0.5, 1.0],
         )
      ),
      child: Column(
         mainAxisSize: MainAxisSize.min, // Ocupa solo el espacio necesario
         children: [
            // Barra de Progreso
            VideoProgressIndicator(
               _controller,
               allowScrubbing: true, // Permite deslizar para buscar
               padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
               colors: VideoProgressColors(
                  playedColor: Theme.of(context).colorScheme.primary,
                  bufferedColor: Colors.grey[600]!,
                  backgroundColor: Colors.transparent, // Fondo ya está en el Container
               ),
            ),
            // Fila con botón Play/Pause y Tiempo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tiempo Actual / Duración Total
                   ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, VideoPlayerValue value, child) {
                         return Text(
                            '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                         );
                      },
                   ),
                  // Botón Play/Pause Central
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 40, // Más grande
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  // Espaciador para centrar el botón play/pause (o añadir otro control aquí)
                   const SizedBox(width: 48), // Ajusta según sea necesario
                ],
              ),
            ),
         ],
      ),
    );
  }

  // Formatea la duración para mostrar MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}