// lib/src/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

// Data Sources
import '../../features/video_management/data/datasources/video_local_datasource.dart';
import '../../features/video_management/data/datasources/file_storage_datasource.dart';

// Repositories
import '../../features/video_management/data/repositories/video_repository_impl.dart';
import '../../features/video_management/domain/repositories/video_repository.dart';

// Use Cases
import '../../features/video_management/domain/usecases/get_active_videos.dart';
import '../../features/video_management/domain/usecases/add_video.dart';
import '../../features/video_management/domain/usecases/archive_video.dart';
import '../../features/video_management/domain/usecases/delete_video.dart';
import '../../features/video_management/domain/usecases/rename_video.dart';
import '../../features/video_management/domain/usecases/add_tag_to_video.dart';
import '../../features/video_management/domain/usecases/remove_tag_from_video.dart';
import '../../features/video_management/domain/usecases/get_all_tags.dart';

// Providers
import '../../features/video_management/presentation/providers/video_provider.dart';

// Models
import '../../features/video_management/data/models/video_model.dart';

// Services
import '../../features/video_picker/video_picker_service.dart';

// Constants
import '../constants.dart';

final sl = GetIt.instance;

/// Inicializa todas las dependencias de la aplicación
Future<void> initializeDependencies() async {
  // =========================================================================
  // EXTERNAL (Hive Box)
  // =========================================================================
  
  final videoBox = await Hive.openBox<VideoModel>(
    AppConstants.videoEntriesBoxName,
  );
  sl.registerSingleton<Box<VideoModel>>(videoBox);

  // =========================================================================
  // DATA SOURCES
  // =========================================================================
  
  sl.registerLazySingleton<VideoLocalDataSource>(
    () => VideoLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<FileStorageDataSource>(
    () => FileStorageDataSourceImpl(),
  );

  // =========================================================================
  // REPOSITORIES
  // =========================================================================
  
  sl.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(
      sl<Box<VideoModel>>(),
      localDataSource: sl(),
      fileStorage: sl(),
    ),
  );

  sl.registerLazySingleton<VideoRepositoryImpl>(
    () => VideoRepositoryImpl(
      sl<Box<VideoModel>>(),
      localDataSource: sl(),
      fileStorage: sl(),
    ),
  );

  // =========================================================================
  // USE CASES
  // =========================================================================
  
  sl.registerLazySingleton(() => GetActiveVideos(sl()));
  sl.registerLazySingleton(() => AddVideo(sl()));
  sl.registerLazySingleton(() => ArchiveVideo(sl()));
  sl.registerLazySingleton(() => DeleteVideo(sl()));
  sl.registerLazySingleton(() => RenameVideo(sl()));
  sl.registerLazySingleton(() => AddTagToVideo(sl()));
  sl.registerLazySingleton(() => RemoveTagFromVideo(sl()));
  sl.registerLazySingleton(() => GetAllTags(sl()));

  // =========================================================================
  // PROVIDERS (State Management)
  // =========================================================================
  
  sl.registerFactory(
    () => VideoProvider(
      getActiveVideos: sl(),
      addVideo: sl(),
      archiveVideo: sl(),
      deleteVideo: sl(),
      renameVideo: sl(),
      addTagToVideo: sl(),
      removeTagFromVideo: sl(),
      getAllTags: sl(),
    ),
  );

  // =========================================================================
  // SERVICES
  // =========================================================================
  
  sl.registerLazySingleton(() => VideoPickerService());
}