// lib/src/features/gallery/widgets/video_grid_item.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar Web
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../video_data/models/video_entry.dart';
import '../../analyzer/screens/analyzer_screen.dart';

class VideoGridItem extends StatelessWidget {
  final VideoEntry entry;
  final Function(BuildContext context, VideoEntry entry, Offset tapPosition) onLongPress; // Sigue siendo necesario para móvil

  const VideoGridItem({
    super.key,
    required this.entry,
    required this.onLongPress,
  });

  void _navigateToAnalyzer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyzerScreen(videoPath: entry.videoPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayTitle = entry.displayName?.isNotEmpty == true
        ? entry.displayName!
        : p.basenameWithoutExtension(entry.videoPath);

    Offset? longPressPosition;

    // Determina si mostrar el botón de tres puntos
    final bool isDesktopOrWeb = (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) || kIsWeb;

    return GestureDetector(
      onTap: () => _navigateToAnalyzer(context),
      onLongPressStart: (details) => longPressPosition = details.globalPosition,
      onLongPress: () {
        // Mantenemos la pulsación larga para móvil
        if (longPressPosition != null) {
          onLongPress(context, entry, longPressPosition!);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack( // Usamos Stack para superponer el botón de menú
          fit: StackFit.expand, // Asegura que el Stack ocupe toda la celda
          children: [
            // Contenido principal (Miniatura + Footer)
            GridTile(
              footer: GridTileBar(
                backgroundColor: Colors.black54,
                title: Text(
                  displayTitle,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              child: _buildThumbnail(),
            ),

            // --- Botón Tres Puntos (Condicional) ---
            if (isDesktopOrWeb) // Muestra solo en escritorio o web
              Positioned(
                top: 4,
                right: 4,
                child: Container( // Añade un fondo semitransparente para visibilidad
                   decoration: BoxDecoration(
                     color: Colors.black.withOpacity(0.4),
                     shape: BoxShape.circle,
                   ),
                  child: Material( // Necesario para InkWell y splash
                     color: Colors.transparent,
                     child: IconButton(
                        icon: const Icon(Icons.more_vert, size: 18),
                        color: Colors.white.withOpacity(0.8),
                        tooltip: 'Opciones',
                        padding: EdgeInsets.zero, // Ajusta padding
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32), // Tamaño pequeño
                        splashRadius: 18, // Radio del splash
                        onPressed: () {
                           // Obtenemos el RenderBox del IconButton para posicionar el menú
                           final RenderBox button = context.findRenderObject() as RenderBox;
                           final Offset offset = button.localToGlobal(Offset.zero);
                           // Ajusta la posición para que el menú aparezca cerca del botón
                           final Offset menuPosition = offset + const Offset(0, 30); // Un poco abajo
                           // Llama al mismo callback que onLongPress
                           onLongPress(context, entry, menuPosition);
                        },
                     ),
                  ),
                ),
              ),
            // ------------------------------------
          ],
        ),
      ),
    );
  } // Fin build()

  // --- Helpers _buildThumbnail, _buildPlaceholderIcon, _buildErrorIcon (sin cambios) ---
  Widget _buildThumbnail() { /* ... (igual que antes) ... */
    if ((Platform.isAndroid || Platform.isIOS) && entry.thumbnailPath != null) {
      final thumbFile = File(entry.thumbnailPath!);
      return FutureBuilder<bool>(
        future: thumbFile.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done || snapshot.hasError || !snapshot.data!) {
            return _buildPlaceholderIcon();
          }
          return Image.file( thumbFile, key: ValueKey(entry.key ?? entry.thumbnailPath), fit: BoxFit.cover, frameBuilder: (context, child, frame, wasSyncLoaded) { if (wasSyncLoaded || frame != null) return child; return Container(color: Colors.grey[850]); }, errorBuilder: (context, error, stackTrace) { return _buildErrorIcon(); }, );
        },
      );
    } else { return _buildPlaceholderIcon(); }
  }
  Widget _buildPlaceholderIcon() { /* ... (igual que antes) ... */
     return Container( decoration: BoxDecoration( color: Colors.grey[850], border: Border.all(color: Colors.grey[700]!, width: 0.5), ), child: const Icon( Icons.videocam_off_outlined, color: Colors.white38, size: 40, ), );
  }
  Widget _buildErrorIcon() { /* ... (igual que antes) ... */
     return Container( color: Colors.grey[850], child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)), );
  }
  // ----------------------------------------------------------------------------------

} // Fin VideoGridItem