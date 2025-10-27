// lib/src/features/video_management/presentation/widgets/video_grid_item.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/video.dart';
import '../screens/analyzer_screen.dart';

class VideoGridItem extends StatelessWidget {
  final Video video;
  final Function(BuildContext context, Video video, Offset tapPosition) onLongPress;

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
            // Thumbnail optimizado
            _OptimizedThumbnail(
              video: video,
              displayTitle: displayTitle,
            ),

            // Botón Tres Puntos (Condicional)
            if (isDesktopOrWeb)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, size: 18),
                      color: Colors.white.withOpacity(0.8),
                      tooltip: 'Opciones',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      splashRadius: 18,
                      onPressed: () {
                        final RenderBox button = context.findRenderObject() as RenderBox;
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
}

// Widget separado para thumbnail - mejora performance
class _OptimizedThumbnail extends StatelessWidget {
  final Video video;
  final String displayTitle;

  const _OptimizedThumbnail({
    required this.video,
    required this.displayTitle,
  });

  @override
  Widget build(BuildContext context) {
    return GridTile(
      footer: GridTileBar(
        backgroundColor: Colors.black54,
        title: Text(
          displayTitle,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: const TextStyle(fontSize: 10),
        ),
      ),
      child: _buildThumbnailContent(),
    );
  }

  Widget _buildThumbnailContent() {
    // Solo intentar cargar thumbnail en móvil
    if ((Platform.isAndroid || Platform.isIOS) && video.thumbnailPath != null) {
      return _MobileThumbnail(thumbnailPath: video.thumbnailPath!, videoId: video.id);
    }
    return _buildPlaceholderIcon();
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
}

// Widget separado para thumbnail móvil - evita reconstrucciones innecesarias
class _MobileThumbnail extends StatefulWidget {
  final String thumbnailPath;
  final String videoId;

  const _MobileThumbnail({
    required this.thumbnailPath,
    required this.videoId,
  });

  @override
  State<_MobileThumbnail> createState() => _MobileThumbnailState();
}

class _MobileThumbnailState extends State<_MobileThumbnail>
    with AutomaticKeepAliveClientMixin {
  File? _thumbFile;
  bool _exists = false;
  bool _checked = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkThumbnail();
  }

  Future<void> _checkThumbnail() async {
    _thumbFile = File(widget.thumbnailPath);
    final exists = await _thumbFile!.exists();
    if (mounted) {
      setState(() {
        _exists = exists;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (!_checked) {
      return Container(color: Colors.grey[850]);
    }

    if (!_exists || _thumbFile == null) {
      return _buildPlaceholderIcon();
    }

    return Image.file(
      _thumbFile!,
      key: ValueKey(widget.videoId),
      fit: BoxFit.cover,
      cacheWidth: 400, // Limita el tamaño en memoria
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded || frame != null) return child;
        return Container(color: Colors.grey[850]);
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorIcon();
      },
    );
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