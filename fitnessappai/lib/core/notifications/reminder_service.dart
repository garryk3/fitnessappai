import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:fitnessappai/core/domain/models/workout_reminder.dart';
import 'package:fitnessappai/core/notifications/notification_log.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';

/// Статус разрешений на уведомления.
class NotificationPermissionStatus {
  const NotificationPermissionStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsEnabled,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;
}

/// Управление еженедельными уведомлениями о тренировочных днях.
///
/// Планирование через [FlutterLocalNotificationsPlugin] с повторением
/// `dayOfWeekAndTime`. Идентификатор уведомления совпадает с
/// [WorkoutReminder.programDayId], поэтому отмена и перепланирование
/// выполняются по id дня.
class ReminderService {
  ReminderService({
    required this._repository,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final WorkoutReminderRepository _repository;
  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelId = 'workout_reminders';
  static const String _channelName = 'Напоминания о тренировках';
  static const String _channelDescription =
      'Еженедельные напоминания о тренировочных днях';
  static const String _iconName = 'ic_stat_launcher';
  static const String _soundName = 'notification';

  bool _initialized = false;

  void Function(int programDayId)? _onReminderTapped;
  int? _pendingProgramDayId;

  /// Обработчик тапа по уведомлению; получает `programDayId` из payload.
  ///
  /// Задаётся слоем приложения, у которого есть роутер: [ReminderService]
  /// создаётся в контейнере до появления UI.
  void Function(int programDayId)? get onReminderTapped => _onReminderTapped;

  set onReminderTapped(void Function(int programDayId)? handler) {
    _onReminderTapped = handler;
    final pending = _pendingProgramDayId;
    if (handler != null && pending != null) {
      _pendingProgramDayId = null;
      handler(pending);
    }
  }

  /// Статус разрешений на уведомления.
  Future<NotificationPermissionStatus> checkPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      // На не-Android платформах локальных уведомлений нет вовсе, поэтому
      // оба флага всегда «не выдано». Прежде здесь возвращалось true/true,
      // а позже — notificationsEnabled вычислялся из наличия
      // запланированных напоминаний, что смешивало статус разрешения с
      // состоянием расписания и снова показывало ложное «выдано».
      return const NotificationPermissionStatus(
        notificationsEnabled: false,
        exactAlarmsEnabled: false,
      );
    }
    final notificationsEnabled =
        await android.areNotificationsEnabled() ?? false;
    final exactAlarmsEnabled =
        await android.canScheduleExactNotifications() ?? false;
    return NotificationPermissionStatus(
      notificationsEnabled: notificationsEnabled,
      exactAlarmsEnabled: exactAlarmsEnabled,
    );
  }

  /// Запрашивает только разрешение на уведомления и возвращает свежий статус.
  ///
  /// Системный диалог Android 13+ показывается лишь один раз; если после
  /// запроса уведомления всё ещё отключены, открывает системные настройки
  /// уведомлений приложения. При выдаче разрешения перепланирует напоминания,
  /// которые могли быть пропущены, пока уведомления были отключены.
  Future<NotificationPermissionStatus> requestNotificationsPermission() async {
    await _requestNotifications();
    final status = await checkPermissions();
    if (status.notificationsEnabled) {
      await rescheduleAll();
    }
    return status;
  }

  /// Запрашивает только разрешение на точные будильники и возвращает свежий
  /// статус.
  ///
  /// На Android 12+ открывает системный экран «Будильники и напоминания».
  /// При выдаче разрешения перепланирует напоминания в точном режиме.
  Future<NotificationPermissionStatus> requestExactAlarmsPermission() async {
    await _requestExactAlarms();
    final status = await checkPermissions();
    if (status.exactAlarmsEnabled) {
      await rescheduleAll();
    }
    return status;
  }

  Future<void> _requestNotifications() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return;
    }
    await android.requestNotificationsPermission();
    final enabled = await android.areNotificationsEnabled() ?? false;
    if (!enabled) {
      await android.openAppNotificationSettings();
    }
  }

  Future<void> _requestExactAlarms() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return;
    }
    final canExact = await android.canScheduleExactNotifications() ?? false;
    if (canExact) {
      return;
    }
    await android.requestExactAlarmsPermission();
  }

  /// Инициализирует часовой пояс, плагин и канал уведомлений.
  ///
  /// Разрешения (уведомления, точные будильники) при старте не запрашивает —
  /// это делается явно из экрана «Настройки», чтобы не открывать системные
  /// диалоги/экраны помимо воли пользователя.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await _initTimeZone();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings(_iconName),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestSoundPermission: true,
        requestBadgePermission: true,
      ),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Открыть'),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(_soundName),
        enableVibration: true,
      );
      await android.createNotificationChannel(channel);
    }
    _initialized = true;
    // Приложение могло быть запущено тапом по уведомлению: событие дошло до
    // плагина до инициализации, поэтому payload приходит только здесь.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if ((launchDetails?.didNotificationLaunchApp ?? false) &&
        launchResponse != null) {
      handleNotificationResponse(launchResponse);
    }
  }

  /// Разбирает нажатие на уведомление и передаёт `programDayId` обработчику.
  ///
  /// Открыт наружу (а не приватный метод) ради тестов: логика отложенной
  /// доставки payload'а — единственное, что отличает запуск тапом от обычного
  /// старта, и она обязана быть покрыта.
  @visibleForTesting
  void handleNotificationResponse(NotificationResponse response) {
    final programDayId = int.tryParse(response.payload ?? '');
    if (programDayId == null) {
      return;
    }
    final handler = _onReminderTapped;
    if (handler == null) {
      // Приложение стартовало тапом по уведомлению: обработник появится
      // только после сборки UI, payload ждёт его.
      _pendingProgramDayId = programDayId;
      return;
    }
    handler(programDayId);
  }

  /// Планирует еженедельное уведомление для дня по [dayOfWeek].
  Future<void> schedule(
    WorkoutReminder reminder, {
    required int dayOfWeek,
    required String programName,
    required int dayNumber,
  }) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      // Планируемые локальные уведомления поддерживает только Android. Без
      // этой проверки прямой вызов (например, при сохранении программы)
      // дошёл бы до zonedSchedule и на Linux попытался завести DBus-будильник,
      // а на web упал бы с MissingPluginException.
      return;
    }
    final enabled = await android.areNotificationsEnabled() ?? false;
    if (!enabled) {
      logNotificationIssue(
        'Уведомления отключены пользователем, пропуск планирования '
        'дня ${reminder.programDayId}',
      );
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = nextInstance(
      now,
      dayOfWeek: dayOfWeek,
      hour: reminder.hour,
      minute: reminder.minute,
    );
    final canExact = await android.canScheduleExactNotifications() ?? false;
    await _plugin.zonedSchedule(
      id: reminder.programDayId,
      title: programName,
      body: 'Тренировка: день $dayNumber',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(_soundName),
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: reminder.programDayId.toString(),
    );
  }

  /// Отменяет уведомление дня по [programDayId].
  Future<void> cancel(int programDayId) async {
    await _plugin.cancel(id: programDayId);
  }

  /// Отменяет все запланированные уведомления.
  ///
  /// Нужен перед полной перепланировкой: аварийные будильники удалённых дней
  /// иначе остаются жить и напоминают о несуществующих тренировках.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Перепланирует все сохранённые напоминания (после импорта БД).
  ///
  /// Ошибка отдельного дня не должна срывать перепланирование остальных:
  /// иначе одно «битое» напоминание тихо оставляет весь список неактуальным.
  Future<void> rescheduleAll() async {
    // Планируемые локальные уведомления есть только на Android. На остальных
    // платформах расписание нечего переносить: `schedule()` там всё равно
    // дошёл бы до `zonedSchedule` и попытался завести датчиковый будильник
    // (DBus), который без запущенного приложения не сработает никогда.
    if (_plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >() ==
        null) {
      return;
    }
    final items = await _repository.allScheduled();
    for (final item in items) {
      final programDayId = item.reminder.programDayId;
      try {
        if (item.dayOfWeek == null || !item.reminder.enabled) {
          await cancel(programDayId);
          continue;
        }
        await schedule(
          item.reminder,
          dayOfWeek: item.dayOfWeek!,
          programName: item.programName,
          dayNumber: item.dayNumber,
        );
      } catch (e, st) {
        logNotificationIssue(
          'Не удалось перепланировать напоминание дня $programDayId',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Ближайшее будущее вхождение дня недели [dayOfWeek] в [hour]:[minute].
  ///
  /// [dayOfWeek]: 1 — понедельник … 7 — воскресенье (как у [DateTime.weekday]).
  @visibleForTesting
  static tz.TZDateTime nextInstance(
    tz.TZDateTime now, {
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) {
    final daysUntil = (dayOfWeek - now.weekday) % 7;
    var scheduled = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + daysUntil,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }

  /// Инициализирует базу часовых поясов и локальную зону.
  ///
  /// Без явного `setLocalLocation` планирование уходит в UTC, и уведомления
  /// приходят со сдвигом на разницу часов — молча. Поэтому неудача видна в
  /// логе, даже когда часовой пояс определить не удалось.
  Future<void> _initTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } on Exception catch (e) {
      logNotificationIssue(
        'Не удалось определить локальный часовой пояс, напоминания '
        'планируются в UTC',
        error: e,
      );
    }
  }
}
