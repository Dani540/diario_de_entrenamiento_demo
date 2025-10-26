// lib/src/core/constants.dart
// Constantes centralizadas de la aplicación

class AppConstants {
  // Claves de SharedPreferences
  static const String gridSizePrefKey = 'gallery_grid_size';
  static const String showFabPrefKey = 'show_gallery_fab';
  static const String keepArchivedTagsPrefKey = 'keep_archived_tags';
  
  // Nombres de cajas de Hive
  static const String videoEntriesBoxName = 'videoEntriesBox';
  
  // Directorios
  static const String videosSubdirectory = 'videos';
  static const String thumbnailsSubdirectory = 'thumbnails';
  
  // Configuración de thumbnails
  static const int thumbnailMaxWidth = 200;
  static const int thumbnailQuality = 80;
  
  // Configuración de la galería
  static const int defaultGridSize = 3;
  static const int minGridSize = 2;
  static const int maxGridSize = 4;
  
  // Duraciones de animación
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 2);
}