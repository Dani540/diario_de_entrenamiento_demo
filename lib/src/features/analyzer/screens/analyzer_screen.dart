import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Solo para Hive.box()

// Asegúrate que las rutas coincidan con tu estructura
import '../../video_data/models/video_entry.dart';
// Quitamos import de DatabaseService si accedemos directo a Hive.box
// import '../../video_data/services/database_service.dart';

class AnalyzerScreen extends StatefulWidget {
  final String videoPath; // Recibe la ruta del video

  const AnalyzerScreen({super.key, required this.videoPath});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  final TextEditingController _tagController = TextEditingController();
  VideoEntry? _currentVideoEntry; // Referencia al objeto en Hive
  List<String> _tags = []; // Lista local para la UI (se sincroniza desde _currentVideoEntry)
  double _currentPlaybackSpeed = 1.0;
  bool _showControls = true; // Para mostrar/ocultar controles al tocar video

  @override
  void initState() {
    super.initState();
    _loadVideoEntry(); // Carga la entrada de la DB ANTES de inicializar el video

    // Inicializa el controlador de video usando Uri.file
    _controller = VideoPlayerController.file(File(widget.videoPath));

    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      // Forzamos el redibujo para que se muestre el primer frame
      if (mounted) setState(() {});
      _controller.setLooping(true); // El video se repetirá
      // _controller.play(); // No iniciamos automáticamente
    }).catchError((error) {
      // Manejo básico de errores si el video no carga
       print("Error al inicializar video: $error");
       // Mostramos mensaje y volvemos atrás si hay error al cargar
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error al cargar el video: ${error.toString()}')),
           );
           Navigator.of(context).pop(); // Vuelve a la pantalla anterior
         }
       });
    });

    // Listener para actualizar estado de reproducción (botón play/pause, tiempo)
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  // Carga la entrada de VideoEntry desde Hive buscando por 'videoPath'
  void _loadVideoEntry() {
    final box = Hive.box<VideoEntry>('videoEntriesBox');
    try {
      // Usamos firstWhere para encontrar la entrada
      _currentVideoEntry = box.values.firstWhere(
        (entry) => entry.videoPath == widget.videoPath,
      );
      // Sincronizamos la lista local _tags con la de Hive al cargar
      _tags = List<String>.from(_currentVideoEntry!.tags);
    } catch (e) { // Captura el error si no se encuentra (StateError de firstWhere)
      print("Error: No se encontró VideoEntry para ${widget.videoPath}. Error: $e");
      // Si no se encuentra, mostramos error y volvemos atrás
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Error: No se encontró la información del video.')),
           );
           Navigator.of(context).pop();
         }
       });
    }
  }

  // --- Funciones para Tags ---
  void _addTag() {
    final String tag = _tagController.text.trim().toLowerCase(); // Guardamos en minúsculas
    if (tag.isNotEmpty && _currentVideoEntry != null) {
      if (!_tags.contains(tag)) {
        setState(() => _tags.add(tag)); // Actualiza UI inmediatamente
        _currentVideoEntry!.addTag(tag); // addTag guarda en Hive
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
      setState(() => _tags.remove(tag)); // Actualiza UI
      _currentVideoEntry!.removeTag(tag); // removeTag guarda en Hive
    }
  }

  // --- Funciones para Controles de Video ---
  void _togglePlayPause() {
    if (!_controller.value.isInitialized) return; // No hacer nada si no está listo
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
    // Es MUY importante hacer dispose del controller para liberar recursos
    _controller.dispose();
    _tagController.dispose();
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
      body: Column( // Column principal: Video arriba, Contenido abajo
        children: [
          // --- Zona del Video Player ---
          Flexible( // Permite que el video tome espacio, pero sin causar overflow
             fit: FlexFit.loose, // El hijo puede ser más pequeño que el espacio asignado
            child: GestureDetector(
              onTap: _toggleControlsVisibility,
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  // Cuando el video está listo
                  if (snapshot.connectionState == ConnectionState.done && _controller.value.isInitialized) {
                    return ConstrainedBox( // Limita la altura máxima del video
                      constraints: BoxConstraints(
                        // No más del 60% de la altura de la pantalla
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: AspectRatio( // Mantiene la proporción del video
                        aspectRatio: _controller.value.aspectRatio,
                        child: Stack( // Para superponer controles
                          alignment: Alignment.bottomCenter,
                          children: <Widget>[
                            VideoPlayer(_controller),
                            // Controles que aparecen/desaparecen
                            AnimatedOpacity(
                               opacity: _showControls ? 1.0 : 0.0,
                               duration: const Duration(milliseconds: 300),
                               child: _buildControlsOverlay(), // Usa el widget auxiliar
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  // Si hubo un error (ya manejado en initState, pero por si acaso)
                  else if (snapshot.hasError) {
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
                  // Mientras carga, muestra indicador
                  else {
                    return const AspectRatio(
                      aspectRatio: 16 / 9, // Placeholder
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              ),
            ),
          ), // Fin del Flexible del video

          // --- Zona de Contenido Scrollable ---
          Expanded( // Ocupa todo el espacio vertical restante
            child: SingleChildScrollView( // Habilita el scroll si el contenido es muy alto
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0), // Padding arriba y lados
              child: Column( // Contenido organizado verticalmente
                crossAxisAlignment: CrossAxisAlignment.start, // Alinea textos a la izquierda
                children: [
                  // --- Controles de Velocidad ---
                   Text('Velocidad:', style: Theme.of(context).textTheme.bodySmall), // Texto más pequeño
                   const SizedBox(height: 4),
                   Wrap( // Organiza los botones de velocidad
                      spacing: 8.0, // Espacio horizontal
                      runSpacing: 0.0, // Sin espacio vertical extra si van a otra línea
                      children: [0.25, 0.5, 1.0, 1.5, 2.0]
                          .map((speed) => _buildSpeedButton(speed))
                          .toList(),
                    ),
                   const SizedBox(height: 20), // Espacio antes de los tags

                  // --- Zona de Tags ---
                  Text('Etiquetas (Movimientos):', style: Theme.of(context).textTheme.titleSmall), // Título un poco más pequeño
                  const SizedBox(height: 8),
                  Row( // Para el campo de texto y el botón de añadir
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: 'Añadir nuevo tag...',
                            isDense: true, // Reduce altura
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8), // Ajusta padding interno
                          ),
                          onSubmitted: (_) => _addTag(), // Añade al presionar Enter/Enviar
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: Theme.of(context).colorScheme.primary, // Color del tema
                        onPressed: _addTag,
                        tooltip: 'Añadir Tag',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Mostrar los tags actuales
                   _tags.isEmpty
                     ? const Padding( // Mensaje si no hay tags
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No hay tags añadidos.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                     )
                     : Wrap( // Muestra los chips con los tags
                       spacing: 6.0,
                       runSpacing: 4.0, // Espacio vertical si hay varias líneas
                       children: _tags.map((tag) => Chip(
                         label: Text(tag),
                         labelStyle: const TextStyle(fontSize: 12), // Letra más pequeña
                         onDeleted: () => _removeTag(tag), // Permite eliminar
                         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Menos padding
                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0), // Ajusta padding
                         deleteIconColor: Colors.redAccent.withOpacity(0.7),
                         deleteIcon: const Icon(Icons.close, size: 14), // Icono de borrar más pequeño
                       )).toList(),
                     ),

                  // Espacio al final para que el último elemento no quede pegado abajo
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ), // Fin del Expanded del contenido
        ],
      ), // Fin del Column principal
    ); // Fin del Scaffold
  }

  // --- Widgets Auxiliares ---

  // Botón para control de velocidad (usando ChoiceChip para mejor UI)
  Widget _buildSpeedButton(double speed) {
    bool isActive = _currentPlaybackSpeed == speed;
    return ChoiceChip(
      label: Text('${speed}x'),
      labelStyle: TextStyle(fontSize: 12, color: isActive ? Theme.of(context).colorScheme.onPrimary : null),
      selected: isActive,
      onSelected: (_) => _setPlaybackSpeed(speed),
      selectedColor: Theme.of(context).colorScheme.primary, // Color cuando está activo
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant, // Color de fondo normal
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      visualDensity: VisualDensity.compact,
       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // Widget para los controles superpuestos en el video
  Widget _buildControlsOverlay() {
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
                   // Podrías añadir más controles aquí (volumen, pantalla completa, etc.)
                   const Spacer(), // Empuja los siguientes elementos a la derecha (si los hubiera)
                ],
              ),
            ),
         ],
      ),
    );
  }

  // Formatea la duración para mostrar MM:SS
  String _formatDuration(Duration duration) {
    // Maneja caso de duración desconocida (puede pasar al inicio)
    if (duration == Duration.zero) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}