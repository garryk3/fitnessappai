import 'dart:developer';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Удерживает процесс тренировки живым при сворачивании/блокировке экрана
/// через foreground service с постоянным уведомлением.
abstract class WorkoutForegroundService {
  Future<void> start({required String title, required String text});

  Future<void> update({required String title, required String text});

  Future<void> stop();
}

/// Callback, запускающий обработчик задачи в изоляте сервиса. Должен быть
/// top-level функцией (`@pragma('vm:entry-point')`).
@pragma('vm:entry-point')
void workoutForegroundServiceCallback() {
  FlutterForegroundTask.setTaskHandler(WorkoutForegroundTaskHandler());
}

/// Минимальный обработчик: foreground service нужен только для удержания
/// процесса и показа уведомления; таймеры живут в основном изоляте.
class WorkoutForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Реализация [WorkoutForegroundService] на `flutter_foreground_task`.
class FlutterForegroundTaskService implements WorkoutForegroundService {
  static const int _serviceId = 256;
  static const String _channelId = 'workout_active';

  bool _initialized = false;

  void _ensureInitialized() {
    if (_initialized) {
      return;
    }
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: 'Активная тренировка',
        channelDescription: 'Показывается во время выполнения тренировки',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
      ),
    );
    _initialized = true;
  }

  @override
  Future<void> start({required String title, required String text}) async {
    try {
      _ensureInitialized();
      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        serviceTypes: [ForegroundServiceTypes.specialUse],
        notificationTitle: title,
        notificationText: text,
        callback: workoutForegroundServiceCallback,
      );
    } catch (e) {
      log('Не удалось запустить foreground service', error: e);
    }
  }

  @override
  Future<void> update({required String title, required String text}) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
      }
    } catch (e) {
      log('Не удалось обновить foreground service', error: e);
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      log('Не удалось остановить foreground service', error: e);
    }
  }
}

/// Заглушка для тестов: фиксирует вызовы, но не запускает сервис.
class StubWorkoutForegroundService implements WorkoutForegroundService {
  int startCalls = 0;
  int updateCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> start({required String title, required String text}) async {
    startCalls++;
  }

  @override
  Future<void> update({required String title, required String text}) async {
    updateCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}
