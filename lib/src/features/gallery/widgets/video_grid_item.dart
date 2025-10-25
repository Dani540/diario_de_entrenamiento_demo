// lib/src/features/gallery/widgets/video_grid_item.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../video_data/models/video_entry.dart';
import '../../analyzer/screens/analyzer_screen.dart'; // Para navegación

class VideoGridItem extends StatelessWidget {
  final VideoEntry entry;
  final Function(BuildContext context, VideoEntry entry, Offset tapPosition) onLongPress;

  const VideoGridItem({
    super.key,
    required this.entry,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final String displayTitle = entry.displayName?.isNotEmpty == true
        ? entry.displayName!
        : p.basenameWithoutExtension(entry.videoPath);

    Offset? longPressPosition;

    return GestureDetector(
      onTap: () => _navigateToAnalyzer(context, entry.videoPath),
      onLongPressStart: (details) => longPressPosition = details.globalPosition,
      onLongPress: () {
         if (longPressPosition != null) {
            // Pasamos el context del build method de este widget
            onLongPress(context, entry, longPressPosition!);
         }
      },   
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: GridTile(
          footer: GridTileBar(
            backgroundColor: Colors.black54,
            title: Text(
              displayTitle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          child: _buildThumbnail(), // Usa un método helper
        ),
      ),
    );
  }

   // Widget Auxiliar para Thumbnail o Placeholder
   Widget _buildThumbnail() {
      if ((Platform.isAndroid || Platform.isIOS) && entry.thumbnailPath != null) {
          final thumbFile = File(entry.thumbnailPath!);
          return FutureBuilder<bool>(
              future: thumbFile.exists(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done || snapshot.hasError || !snapshot.data!) {
                  return _buildPlaceholderIcon();
                }
                return Image.file(
                  thumbFile,
                  key: ValueKey(entry.key ?? entry.thumbnailPath), // Usa key de Hive si está disponible
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, wasSyncLoaded) {
                    if (wasSyncLoaded || frame != null) return child;
                    return Container(color: Colors.grey[850]);
                  },
                  errorBuilder: (context, error, stackTrace) {
                     // print("Error cargando thumbnail ${entry.thumbnailPath}: $error"); // Quitado
                    return _buildErrorIcon();
                  },
                );
              }
          );
      } else {
        return _buildPlaceholderIcon();
      }
   }

  // Placeholder estándar
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
   // Icono para error al cargar imagen
   Widget _buildErrorIcon() {
     return Container(
       color: Colors.grey[850],
       child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
     );
   }

  // Navegación (método estático o pasado como callback si prefieres)
  void _navigateToAnalyzer(BuildContext context, String videoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyzerScreen(videoPath: videoPath),
      ),
    );
  }
}