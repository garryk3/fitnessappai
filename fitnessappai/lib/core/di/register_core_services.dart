import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';

/// Регистрация сервисов core-слоя в контейнере.
void registerCoreServices(ServiceLocator sl) {
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
}
