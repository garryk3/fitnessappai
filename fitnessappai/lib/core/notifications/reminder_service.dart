import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:fitnessappai/core/domain/models/workout_reminder.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';

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

  bool _initialized = false;

  /// Инициализирует часовой пояс и плагин, запрашивает разрешения.
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
    await _plugin.initialize(settings: settings);
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    _initialized = true;
  }

  /// Планирует еженедельное уведомление для дня по [dayOfWeek].
  Future<void> schedule(
    WorkoutReminder reminder, {
    required int dayOfWeek,
    required String programName,
    required int dayNumber,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = nextInstance(
      now,
      dayOfWeek: dayOfWeek,
      hour: reminder.hour,
      minute: reminder.minute,
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canExact = await android?.canScheduleExactNotifications() ?? false;
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

  /// Перепланирует все сохранённые напоминания (после импорта БД).
  Future<void> rescheduleAll() async {
    final items = await _repository.allScheduled();
    for (final item in items) {
      if (item.dayOfWeek == null || !item.reminder.enabled) {
        await cancel(item.reminder.programDayId);
        continue;
      }
      await schedule(
        item.reminder,
        dayOfWeek: item.dayOfWeek!,
        programName: item.programName,
        dayNumber: item.dayNumber,
      );
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

  Future<void> _initTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } on Exception {
      // Оставляем локацию по умолчанию (UTC), если таймзону получить нельзя.
    }
  }
}
