import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/register_core_services.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';

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
  registerCoreServices(sl, database: database);
  await seedExercises(
    sl,
    mediaStore: mediaStore,
    seedJsonLoader: seedJsonLoader,
  );
  try {
    await sl.get<ReminderService>().initialize();
  } catch (_) {
    // Напоминания не должны блокировать запуск приложения.
  }
}
