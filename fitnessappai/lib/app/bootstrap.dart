import 'dart:developer';

import 'package:flutter/services.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/app/theme/theme_controller.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/register_core_services.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/core/notifications/notification_log.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_cleanup.dart';
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
  // Записи плана прошлых недель больше не нужны (47.4): чистим на старте,
  // чтобы база не копила мусор даже без открытия экрана плана.
  try {
    await sl.get<PlanScheduleCleaner>().cleanupOldSchedule(DateTime.now());
  } catch (e, st) {
    logNotificationIssue(
      'Ошибка очистки устаревших записей плана',
      error: e,
      stackTrace: st,
      name: 'bootstrap',
    );
  }
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
  } catch (e, st) {
    logNotificationIssue(
      'Ошибка инициализации напоминаний',
      error: e,
      stackTrace: st,
      name: 'bootstrap',
    );
  }
  try {
    await sl.get<ReminderService>().rescheduleAll();
  } catch (e, st) {
    logNotificationIssue(
      'Ошибка перепланирования напоминаний',
      error: e,
      stackTrace: st,
      name: 'bootstrap',
    );
  }
  try {
    // Напоминание, которое система не доставила (задержка inexact-будильника
    // в Doze, отменённые «Остановить приложение» будильники), показываем сразу
    // при запуске — иначе о нём пользователь узнаёт слишком поздно.
    await sl.get<ReminderService>().catchUpMissed();
  } catch (e, st) {
    logNotificationIssue(
      'Пропущенные напоминания не показаны при запуске',
      error: e,
      stackTrace: st,
      name: 'bootstrap',
    );
  }
  try {
    restoredCheckpoint = await _restoreCheckpoint(sl);
  } catch (e) {
    log('Не удалось загрузить checkpoint', error: e, name: 'bootstrap');
  }
}

/// Загружает чекпойнт и возвращает его только «по факту» (задача 57.2):
/// тренировка была начата и не завершена, снимок не старше
/// [WorkoutCheckpoint.ttl], а день программы ещё существует в БД.
/// Невалидный чекпойнт удаляется с диска — восстановление не происходит.
Future<WorkoutCheckpoint?> _restoreCheckpoint(ServiceLocator sl) async {
  final checkpoint = await WorkoutCheckpoint.load();
  if (checkpoint == null) {
    return null;
  }
  final bool expired = checkpoint.startedAt.isBefore(
    DateTime.now().subtract(WorkoutCheckpoint.ttl),
  );
  final bool dayExists = await sl
      .get<ProgramRepository>()
      .getDay(checkpoint.programDayId)
      .then((day) => day != null);
  if (!expired && dayExists) {
    return checkpoint;
  }
  await WorkoutCheckpoint.clear();
  return null;
}
