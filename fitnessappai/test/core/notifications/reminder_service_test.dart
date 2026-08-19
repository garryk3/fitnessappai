import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:fitnessappai/core/domain/models/workout_reminder.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';

class _MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockReminderRepository extends Mock
    implements WorkoutReminderRepository {}

void main() {
  tz_data.initializeTimeZones();

  late _MockNotificationsPlugin plugin;
  late _MockAndroidPlugin android;
  late _MockReminderRepository repository;
  late ReminderService service;

  setUpAll(() {
    registerFallbackValue(tz.TZDateTime(tz.local, 2024, 1, 1));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.exact);
    registerFallbackValue('');
  });

  setUp(() {
    plugin = _MockNotificationsPlugin();
    android = _MockAndroidPlugin();
    repository = _MockReminderRepository();
    service = ReminderService(repository: repository, plugin: plugin);
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
  });

  group('nextInstance', () {
    final now = tz.TZDateTime(tz.local, 2024, 1, 3, 10, 0); // среда

    tz.TZDateTime at(int dayOfWeek, int hour, int minute) =>
        ReminderService.nextInstance(
          now,
          dayOfWeek: dayOfWeek,
          hour: hour,
          minute: minute,
        );

    test('день недели сегодня и время ещё впереди — сегодня', () {
      expect(at(3, 11, 0), tz.TZDateTime(tz.local, 2024, 1, 3, 11, 0));
    });

    test('день недели сегодня и время уже прошло — через неделю', () {
      expect(at(3, 9, 0), tz.TZDateTime(tz.local, 2024, 1, 10, 9, 0));
    });

    test('пятница — через два дня', () {
      expect(at(5, 8, 30), tz.TZDateTime(tz.local, 2024, 1, 5, 8, 30));
    });

    test('воскресенье — через четыре дня', () {
      expect(at(7, 20, 0), tz.TZDateTime(tz.local, 2024, 1, 7, 20, 0));
    });

    test('понедельник — через пять дней', () {
      expect(at(1, 7, 0), tz.TZDateTime(tz.local, 2024, 1, 8, 7, 0));
    });
  });

  group('schedule', () {
    const reminder = WorkoutReminder(
      id: 1,
      programDayId: 42,
      hour: 9,
      minute: 30,
      enabled: true,
    );

    setUp(() {
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.areNotificationsEnabled(),
      ).thenAnswer((_) async => true);
    });

    test('точный режим при наличии разрешения на точные будильники', () async {
      when(
        () => android.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);

      await service.schedule(
        reminder,
        dayOfWeek: 3,
        programName: 'Сплит',
        dayNumber: 2,
      );

      verify(
        () => plugin.zonedSchedule(
          id: 42,
          title: 'Сплит',
          body: 'Тренировка: день 2',
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: '42',
        ),
      ).called(1);
    });

    test('неточный режим без разрешения на точные будильники', () async {
      when(
        () => android.canScheduleExactNotifications(),
      ).thenAnswer((_) async => false);

      await service.schedule(
        reminder,
        dayOfWeek: 5,
        programName: 'Бег',
        dayNumber: 3,
      );

      verify(
        () => plugin.zonedSchedule(
          id: 42,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });

  test('cancel отменяет уведомление по id дня', () async {
    await service.cancel(42);
    verify(() => plugin.cancel(id: 42)).called(1);
  });

  test('rescheduleAll планирует включённые и отменяет остальные', () async {
    final enabled = ReminderSchedule(
      reminder: const WorkoutReminder(
        id: 1,
        programDayId: 10,
        hour: 9,
        minute: 0,
        enabled: true,
      ),
      dayOfWeek: 2,
      programName: 'Сплит',
      dayNumber: 1,
    );
    final disabled = ReminderSchedule(
      reminder: const WorkoutReminder(
        id: 2,
        programDayId: 11,
        hour: 9,
        minute: 0,
        enabled: false,
      ),
      dayOfWeek: 3,
      programName: 'Бег',
      dayNumber: 1,
    );
    final noWeekday = ReminderSchedule(
      reminder: const WorkoutReminder(
        id: 3,
        programDayId: 12,
        hour: 9,
        minute: 0,
        enabled: true,
      ),
      dayOfWeek: null,
      programName: 'Без привязки',
      dayNumber: 1,
    );
    when(
      () => repository.allScheduled(),
    ).thenAnswer((_) async => [enabled, disabled, noWeekday]);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(android);
    when(
      () => android.canScheduleExactNotifications(),
    ).thenAnswer((_) async => true);
    when(() => android.areNotificationsEnabled()).thenAnswer((_) async => true);

    await service.rescheduleAll();

    verify(
      () => plugin.zonedSchedule(
        id: 10,
        title: 'Сплит',
        body: 'Тренировка: день 1',
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: '10',
      ),
    ).called(1);
    verify(() => plugin.cancel(id: 11)).called(1);
    verify(() => plugin.cancel(id: 12)).called(1);
  });
}
