import 'package:path_provider/path_provider.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/database/app_database_path.dart';
import 'package:fitnessappai/core/database/seed/reference_seeder.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/llm/data/unsupported_generator.dart';
import 'package:fitnessappai/features/llm/domain/exercise_content_generator.dart';
import 'package:fitnessappai/features/profile/data/body_measurement_repository.dart';
import 'package:fitnessappai/features/profile/domain/body_measurement_validator.dart';
import 'package:fitnessappai/features/profile/domain/contraindication_service.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';
import 'package:fitnessappai/features/sync/data/local_file_sync_service.dart';
import 'package:fitnessappai/features/sync/domain/sync_service.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

/// Регистрация сервисов core-слоя в контейнере.
void registerCoreServices(ServiceLocator sl, {AppDatabase? database}) {
  sl.registerLazySingleton<AppDatabase>(() => database ?? AppDatabase());
  sl.registerLazySingleton<MediaStore>(() => MediaStore());
  sl.registerLazySingleton<MediaCache>(() => MediaCache());
  sl.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepository(sl.get<AppDatabase>(), sl.get<MediaStore>()),
  );
  sl.registerLazySingleton<ProgramRepository>(
    () => ProgramRepository(sl.get<AppDatabase>()),
  );
  sl.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepository(sl.get<AppDatabase>()),
  );
  sl.registerLazySingleton<StatsAggregator>(
    () => StatsAggregator(
      workoutRepository: sl.get<WorkoutRepository>(),
      exerciseRepository: sl.get<ExerciseRepository>(),
    ),
  );
  sl.registerLazySingleton<ExerciseContentGenerator>(
    () => const UnsupportedGenerator(),
  );
  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepository(sl.get<AppDatabase>()),
  );
  sl.registerLazySingleton<ContraindicationService>(
    () => const ContraindicationService(),
  );
  sl.registerLazySingleton<BodyMeasurementRepository>(
    () => BodyMeasurementRepository(sl.get<AppDatabase>()),
  );
  sl.registerLazySingleton<BodyMeasurementValidator>(
    () => const BodyMeasurementValidator(),
  );
  sl.registerLazySingleton<WorkoutReminderRepository>(
    () => WorkoutReminderRepository(sl.get<AppDatabase>()),
  );
  sl.registerLazySingleton<ReminderService>(
    () => ReminderService(repository: sl.get<WorkoutReminderRepository>()),
  );
  sl.registerLazySingleton<SyncService>(
    () => LocalFileSyncService(
      database: sl.get<AppDatabase>(),
      databaseFilePath: appDatabasePath,
      temporaryDirectoryPath: () async => (await getTemporaryDirectory()).path,
      onImported: () => _rebuildAfterImport(sl),
    ),
  );
}

/// Перестраивает контейнер после импорта БД: пересоздаёт базу из нового
/// файла, заливает справочники и перепланирует напоминания.
Future<void> _rebuildAfterImport(ServiceLocator sl) async {
  sl.reset();
  registerCoreServices(sl);
  final database = sl.get<AppDatabase>();
  await ReferenceSeeder(database).seed();
  final reminders = sl.get<ReminderService>();
  await reminders.initialize();
  await reminders.rescheduleAll();
}
