
// lib/src/features/video_management/data/datasources/file_storage_datasource.dart
import 'dart:io';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/thumbnail_generator.dart';

/// Interfaz para operaciones de almacenamiento de archivos
abstract class FileStorageDataSource {
  Future<String> copyVideoFile(String originalPath);
  Future<String?> generateThumbnail(String videoPath);
  Future<void> deleteFile(String path);
  Future<bool> fileExists(String path);
}

/// Implementación del DataSource de almacenamiento de archivos
class FileStorageDataSourceImpl implements FileStorageDataSource {
  
  @override
  Future<String> copyVideoFile(String originalPath) async {
    return await FileUtils.copyVideoFile(originalPath);
  }

  @override
  Future<String?> generateThumbnail(String videoPath) async {
    return await ThumbnailGenerator.generate(videoPath);
  }

  @override
  Future<void> deleteFile(String path) async {
    await FileUtils.deleteFile(path);
  }

  @override
  Future<bool> fileExists(String path) async {
    return await FileUtils.fileExists(path);
  }
}