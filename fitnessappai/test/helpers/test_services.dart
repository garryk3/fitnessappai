import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';

/// Регистрирует в глобальном [locator] сервисы на in-memory БД.
///
/// Подходит для виджет-тестов, которые рендерят [FitnessAppAi].
/// После каждого теста регистрации сбрасываются, БД закрывается.
void registerTestServices() {
  final db = AppDatabase(executor: NativeDatabase.memory());
  locator.registerInstance<AppDatabase>(db);
  locator.registerLazySingleton<MediaCache>(() => MediaCache());
  locator.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepository(db, MediaStore()),
  );
  addTearDown(() async {
    locator.reset();
    await db.close();
  });
}
