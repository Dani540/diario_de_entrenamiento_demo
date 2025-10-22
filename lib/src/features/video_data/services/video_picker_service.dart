import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoPickerService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickVideoFromGallery() async {
    // 1. Solicitar Permiso
    PermissionStatus status;
    if (await Permission.storage.isPermanentlyDenied || await Permission.photos.isPermanentlyDenied) {
      // El usuario ha denegado permanentemente el permiso.
      // Mostrar un diálogo para ir a la configuración de la app.
      print('Permiso de galería denegado permanentemente.');
      // Aquí podrías mostrar un diálogo con openAppSettings()
      openAppSettings();
      return null;
    }

    // Pide permiso si aún no está concedido
     status = await Permission.photos.request(); // Para iOS >= 14 o storage para Android/iOS < 14
     if (!status.isGranted) {
        status = await Permission.storage.request(); // Fallback o para Android
     }


    if (status.isGranted) {
      // 2. Si el permiso está concedido, abrir la galería
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      return video?.path; // Devuelve la ruta del video o null si no se seleccionó
    } else {
      // 3. Si el permiso es denegado
      print('Permiso de galería denegado.');
      // Podrías mostrar un mensaje al usuario
      return null;
    }
  }
}