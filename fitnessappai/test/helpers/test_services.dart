import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/app/sound/sound_settings_repository.dart';
import 'package:fitnessappai/app/theme/theme_controller.dart';
import 'package:fitnessappai/app/theme/theme_settings_repository.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/llm/data/llm_export_service.dart';
import 'package:fitnessappai/features/profile/data/body_measurement_repository.dart';
import 'package:fitnessappai/features/profile/domain/body_measurement_validator.dart';
import 'package:fitnessappai/features/profile/domain/contraindication_service.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

/// Регистрирует в глобальном [locator] сервисы на in-memory БД.
///
/// Подходит для виджет-тестов, которые рендерят [FitnessAppAi].
/// После каждого теста регистрации сбрасываются, БД закрывается.
void registerTestServices() {
  final db = AppDatabase(executor: NativeDatabase.memory());
  locator.registerInstance<AppDatabase>(db);
  locator.registerLazySingleton<MediaCache>(() => MediaCache());
  locator.registerLazySingleton<ThemeSettingsRepository>(
    () => ThemeSettingsRepository(db),
  );
  locator.registerLazySingleton<ThemeController>(
    () => ThemeController(locator.get<ThemeSettingsRepository>()),
  );
  locator.registerLazySingleton<SoundSettingsRepository>(
    () => SoundSettingsRepository(db),
  );
  locator.registerInstance<SoundService>(StubSoundService());
  locator.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepository(db, MediaStore()),
  );
  locator.registerLazySingleton<ProgramRepository>(() => ProgramRepository(db));
  locator.registerLazySingleton<WorkoutRepository>(() => WorkoutRepository(db));
  locator.registerLazySingleton<LlmExportService>(
    () => LlmExportService(
      programRepository: locator.get<ProgramRepository>(),
      exerciseRepository: locator.get<ExerciseRepository>(),
      workoutRepository: locator.get<WorkoutRepository>(),
    ),
  );
  locator.registerLazySingleton<StatsAggregator>(
    () => StatsAggregator(
      workoutRepository: locator.get<WorkoutRepository>(),
      exerciseRepository: locator.get<ExerciseRepository>(),
    ),
  );
  locator.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepository(db),
  );
  locator.registerLazySingleton<ContraindicationService>(
    () => const ContraindicationService(),
  );
  locator.registerLazySingleton<BodyMeasurementRepository>(
    () => BodyMeasurementRepository(db),
  );
  locator.registerLazySingleton<BodyMeasurementValidator>(
    () => const BodyMeasurementValidator(),
  );
  addTearDown(() async {
    locator.reset();
    await db.close();
  });
}
