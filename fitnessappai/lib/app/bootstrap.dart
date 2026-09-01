import 'dart:developer';

import 'package:flutter/services.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/app/theme/theme_controller.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/register_core_services.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/workout/domain/workout_checkpoint.dart';

/// Восстановленный checkpoint при загрузке приложения.
///
/// Устанавливается в [bootstrap], читается в [AppRouter.create].
WorkoutCheckpoint? restoredCheckpoint;

/// Стартовая инициализация приложения перед `runApp`: регистрация сервисов,
/// заливка стартового набора упражнений и инициализация напоминаний.
///
/// [database] и [mediaStore] позволяют подставить тестовые зависимости
/// (memory-БД и фейковый загрузчик ассетов), [seedJsonLoader] — заменить
/// источник seed-данных.
Future<void> bootstrap({
  ServiceLocator? container,
  AppDatabase? database,
  MediaStore? mediaStore,
  Future<String> Function()? seedJsonLoader,
}) async {
  final sl = container ?? locator;
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  registerCoreServices(sl, database: database);
  await seedExercises(
    sl,
    mediaStore: mediaStore,
    seedJsonLoader: seedJsonLoader,
  );
  await sl.get<ThemeController>().load();
  try {
    await AudioplayersSoundService.configureGlobalContext();
  } catch (e) {
    log('Не удалось настроить AudioContext', error: e, name: 'bootstrap');
  }
  try {
    await sl.get<ReminderService>().initialize();
  } catch (e) {
    log('Ошибка инициализации напоминаний', error: e, name: 'bootstrap');
  }
  try {
    restoredCheckpoint = await WorkoutCheckpoint.load();
  } catch (e) {
    log('Не удалось загрузить checkpoint', error: e, name: 'bootstrap');
  }
}
