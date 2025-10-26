// lib/src/features/video_management/presentation/widgets/video_grid_item.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/video.dart';
import '../screens/analyzer_screen.dart';

class VideoGridItem extends StatelessWidget {
  final Video video;
  final Function(BuildContext context, Video video, Offset tapPosition)
      onLongPress;

  const VideoGridItem({
    super.key,
    required this.video,
    required this.onLongPress,
  });

  void _navigateToAnalyzer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyzerScreen(video: video),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayTitle = video.displayName?.isNotEmpty == true
        ? video.displayName!
        : p.basenameWithoutExtension(video.videoPath);

    Offset? longPressPosition;

    // Determina si mostrar el botón de tres puntos
    final bool isDesktopOrWeb = (!kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) ||
        kIsWeb;

    return GestureDetector(
      onTap: () => _navigateToAnalyzer(context),
      onLongPressStart: (details) => longPressPosition = details.globalPosition,
      onLongPress: () {
        if (longPressPosition != null) {
          onLongPress(context, video, longPressPosition!);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          fit: StackFit.expand,
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

            // Botón Tres Puntos (Condicional)
            if (isDesktopOrWeb)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((255 * 0.4).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, size: 18),
                      color: Colors.white.withAlpha((255 * 0.8).round()),
                      tooltip: 'Opciones',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      splashRadius: 18,
                      onPressed: () {
                        final RenderBox button =
                            context.findRenderObject() as RenderBox;
                        final Offset offset = button.localToGlobal(Offset.zero);
                        final Offset menuPosition = offset + const Offset(0, 30);
                        onLongPress(context, video, menuPosition);
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if ((Platform.isAndroid || Platform.isIOS) && video.thumbnailPath != null) {
      final thumbFile = File(video.thumbnailPath!);
      return FutureBuilder<bool>(
        future: thumbFile.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done ||
              snapshot.hasError ||
              !snapshot.data!) {
            return _buildPlaceholderIcon();
          }
          return Image.file(
            thumbFile,
            key: ValueKey(video.id),
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSyncLoaded) {
              if (wasSyncLoaded || frame != null) return child;
              return Container(color: Colors.grey[850]);
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorIcon();
            },
          );
        },
      );
    } else {
      return _buildPlaceholderIcon();
    }
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border.all(color: Colors.grey[700]!, width: 0.5),
      ),
      child: const Icon(
        Icons.videocam_off_outlined,
        color: Colors.white38,
        size: 40,
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      color: Colors.grey[850],
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }
}