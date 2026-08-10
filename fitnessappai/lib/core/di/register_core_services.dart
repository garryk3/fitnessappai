import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';

/// Регистрация сервисов core-слоя в контейнере.
void registerCoreServices(ServiceLocator sl) {
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  sl.registerLazySingleton<MediaStore>(() => MediaStore());
  sl.registerLazySingleton<MediaCache>(() => MediaCache());
  sl.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepository(sl.get<AppDatabase>(), sl.get<MediaStore>()),
  );
  sl.registerLazySingleton<ProgramRepository>(
    () => ProgramRepository(sl.get<AppDatabase>()),
  );
}
