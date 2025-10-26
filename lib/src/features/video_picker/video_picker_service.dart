// lib/src/features/video_picker/video_picker_service.dart
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Servicio para seleccionar videos de la galería
class VideoPickerService {
  final ImagePicker _picker = ImagePicker();

  /// Selecciona un video de la galería del dispositivo
  /// Retorna la ruta del video o null si se cancela/falla
  Future<String?> pickVideoFromGallery() async {
    // 1. Verificar y solicitar permisos
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      print('Permiso de galería denegado.');
      return null;
    }

    // 2. Abrir galería
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      return video?.path;
    } catch (e) {
      print('Error al seleccionar video: $e');
      return null;
    }
  }

  /// Solicita los permisos necesarios para acceder a la galería
  Future<bool> _requestPermissions() async {
    // Verificar si el permiso está permanentemente denegado
    if (await Permission.storage.isPermanentlyDenied ||
        await Permission.photos.isPermanentlyDenied) {
      print('Permiso de galería denegado permanentemente.');
      // Abrir configuración de la app
      await openAppSettings();
      return false;
    }

    // Solicitar permiso de fotos (iOS >= 14 y Android >= 13)
    PermissionStatus status = await Permission.photos.request();
    
    if (!status.isGranted) {
      // Fallback para storage (Android < 13)
      status = await Permission.storage.request();
    }

    return status.isGranted;
  }

  /// Verifica si los permisos están concedidos
  Future<bool> hasPermissions() async {
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;
    
    return photosStatus.isGranted || storageStatus.isGranted;
  }
}