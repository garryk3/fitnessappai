import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:fitnessappai/app/sound/sound_settings_store.dart';
import 'package:fitnessappai/core/domain/models/workout_reminder.dart';
import 'package:fitnessappai/core/notifications/reminder_catch_up_log.dart';
import 'package:fitnessappai/core/notifications/reminder_delivered_log.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/domain/plan_schedule_item.dart';

class _MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockReminderRepository extends Mock
    implements WorkoutReminderRepository {}

class _MockPlanScheduleRepository extends Mock
    implements PlanScheduleRepository {}

void main() {
  // initialize() ходит в FlutterTimezone через method channel — нужен binding.
  TestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();

  late _MockNotificationsPlugin plugin;
  late _MockAndroidPlugin android;
  late _MockReminderRepository repository;
  late ReminderService service;

  setUpAll(() {
    registerFallbackValue(tz.TZDateTime(tz.local, 2024, 1, 1));
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.exact);
    registerFallbackValue('');
  });

  setUp(() {
    // Launch details — событие уровня процесса, а не экземпляра. Сброс на
    // уровне файла, а не группы: любая будущая группа, зовущая initialize(),
    // иначе молча потеряла бы launch details предыдущего теста.
    resetLaunchDetailsForTests();
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
    when(() => plugin.cancelAll()).thenAnswer((_) async {});
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

  group('requestNotificationsPermission', () {
    setUp(() {
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => repository.allScheduled(),
      ).thenAnswer((_) async => <ReminderSchedule>[]);
    });

    test('запрашивает только уведомления и возвращает свежий статус', () async {
      when(
        () => android.requestNotificationsPermission(),
      ).thenAnswer((_) async => true);
      when(
        () => android.areNotificationsEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => android.canScheduleExactNotifications(),
      ).thenAnswer((_) async => false);

      final status = await service.requestNotificationsPermission();

      expect(status.notificationsEnabled, true);
      expect(status.exactAlarmsEnabled, false);
      verify(() => android.requestNotificationsPermission()).called(1);
      verifyNever(() => android.requestExactAlarmsPermission());
      verify(
        () => repository.allScheduled(),
      ).called(1); // перепланирование после выдачи
    });

    test(
      'если уведомления отключены — открывает системные настройки',
      () async {
        when(
          () => android.requestNotificationsPermission(),
        ).thenAnswer((_) async => false);
        when(
          () => android.areNotificationsEnabled(),
        ).thenAnswer((_) async => false);
        when(
          () => android.canScheduleExactNotifications(),
        ).thenAnswer((_) async => false);
        when(
          () => android.openAppNotificationSettings(),
        ).thenAnswer((_) async => true);

        final status = await service.requestNotificationsPermission();

        expect(status.notificationsEnabled, false);
        verify(() => android.openAppNotificationSettings()).called(1);
        verifyNever(() => android.requestExactAlarmsPermission());
      },
    );
  });

  group('requestExactAlarmsPermission', () {
    setUp(() {
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => repository.allScheduled(),
      ).thenAnswer((_) async => <ReminderSchedule>[]);
    });

    test(
      'запрашивает только точные будильники и возвращает свежий статус',
      () async {
        var canExact = false;
        when(
          () => android.canScheduleExactNotifications(),
        ).thenAnswer((_) async => canExact);
        when(() => android.requestExactAlarmsPermission()).thenAnswer((
          _,
        ) async {
          canExact = true;
          return true;
        });
        when(
          () => android.areNotificationsEnabled(),
        ).thenAnswer((_) async => true);

        final status = await service.requestExactAlarmsPermission();

        expect(status.notificationsEnabled, true);
        expect(status.exactAlarmsEnabled, true);
        verify(() => android.requestExactAlarmsPermission()).called(1);
        verifyNever(() => android.requestNotificationsPermission());
        verify(() => repository.allScheduled()).called(1);
      },
    );

    test('не открывает экран, если разрешение уже выдано', () async {
      when(
        () => android.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
      when(
        () => android.areNotificationsEnabled(),
      ).thenAnswer((_) async => true);

      final status = await service.requestExactAlarmsPermission();

      expect(status.exactAlarmsEnabled, true);
      verifyNever(() => android.requestExactAlarmsPermission());
    });
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

  group('rescheduleDays / cancelDays (47.8, 2г)', () {
    ReminderSchedule scheduleOf(
      int programDayId, {
      required bool enabled,
      int? dayOfWeek = 2,
    }) => ReminderSchedule(
      reminder: WorkoutReminder(
        id: programDayId,
        programDayId: programDayId,
        hour: 9,
        minute: 0,
        enabled: enabled,
      ),
      dayOfWeek: dayOfWeek,
      programName: 'Сплит',
      dayNumber: 1,
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
      when(
        () => android.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
    });

    test('планирует сохранённые напоминания только указанных дней', () async {
      when(() => repository.scheduledForDays(any())).thenAnswer(
        (_) async => [
          scheduleOf(10, enabled: true),
          scheduleOf(11, enabled: true),
        ],
      );

      await service.rescheduleDays([10, 11]);

      verify(() => repository.scheduledForDays([10, 11])).called(1);
      verify(
        () => plugin.zonedSchedule(
          id: 10,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verify(
        () => plugin.zonedSchedule(
          id: 11,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('выключенное напоминание и день без привязки отменяются', () async {
      when(() => repository.scheduledForDays(any())).thenAnswer(
        (_) async => [
          scheduleOf(10, enabled: false),
          scheduleOf(11, enabled: true, dayOfWeek: null),
        ],
      );

      await service.rescheduleDays([10, 11]);

      verify(() => plugin.cancel(id: 10)).called(1);
      verify(() => plugin.cancel(id: 11)).called(1);
      verifyNever(
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
      );
    });

    test('без списка дней ничего не планируется и не отменяется', () async {
      when(
        () => repository.scheduledForDays(any()),
      ).thenAnswer((_) async => []);

      await service.rescheduleDays([]);
      await service.cancelDays([]);

      verifyNever(() => plugin.cancel(id: any(named: 'id')));
    });

    test('cancelDays отменяет уведомления, не трогая другие', () async {
      await service.cancelDays([10, 11]);

      verify(() => plugin.cancel(id: 10)).called(1);
      verify(() => plugin.cancel(id: 11)).called(1);
      verifyNever(() => plugin.cancelAll());
    });

    test('ошибка планирования не прерывает остальные дни', () async {
      when(() => repository.scheduledForDays(any())).thenAnswer(
        (_) async => [
          scheduleOf(10, enabled: true),
          scheduleOf(11, enabled: true),
        ],
      );
      when(
        () => plugin.zonedSchedule(
          id: 10,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
        ),
      ).thenThrow(Exception('boom'));
      when(
        () => plugin.zonedSchedule(
          id: 11,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await service.rescheduleDays([10, 11]);

      verify(
        () => plugin.zonedSchedule(
          id: 11,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('ошибка отмены не прерывает обработку остальных дней', () async {
      when(() => plugin.cancel(id: 10)).thenThrow(Exception('boom'));

      await service.cancelDays([10, 11]);

      verify(() => plugin.cancel(id: 11)).called(1);
    });
  });

  test('cancelAll отменяет все запланированные уведомления', () async {
    await service.cancelAll();

    verify(() => plugin.cancelAll()).called(1);
  });

  test(
    'повторное перепланирование не плодит будильники, а заменяет их',
    () async {
      // id уведомления — programDayId, поэтому повторный rescheduleAll
      // перезаписывает тот же будильник, а не создаёт второй (TC-078).
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.areNotificationsEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => android.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
      when(() => repository.allScheduled()).thenAnswer(
        (_) async => [
          ReminderSchedule(
            reminder: const WorkoutReminder(
              id: 1,
              programDayId: 10,
              hour: 9,
              minute: 0,
            ),
            dayOfWeek: 2,
            programName: 'Сплит',
            dayNumber: 1,
          ),
        ],
      );
      int? scheduledId() =>
          verify(
                () => plugin.zonedSchedule(
                  id: captureAny(named: 'id'),
                  title: any(named: 'title'),
                  body: any(named: 'body'),
                  scheduledDate: any(named: 'scheduledDate'),
                  notificationDetails: any(named: 'notificationDetails'),
                  androidScheduleMode: any(named: 'androidScheduleMode'),
                  matchDateTimeComponents: any(
                    named: 'matchDateTimeComponents',
                  ),
                  payload: any(named: 'payload'),
                ),
              ).captured.last
              as int;

      await service.rescheduleAll();
      final first = scheduledId();

      await service.rescheduleAll();
      final second = scheduledId();

      expect(first, 10);
      expect(second, first, reason: 'id детерминирован, будильник заменяется');
      verifyNever(() => plugin.cancelAll());
    },
  );

  test('rescheduleAll вне Android не планирует и не ходит в БД', () async {
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(null);
    when(
      () => repository.allScheduled(),
    ).thenThrow(StateError('на не-Android расписание не восстанавливается'));

    await expectLater(service.rescheduleAll(), completes);

    verifyNever(() => repository.allScheduled());
    verifyNever(
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
    );
  });

  test('прямой schedule вне Android не доходит до плагина', () async {
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(null);

    await expectLater(
      service.schedule(
        const WorkoutReminder(id: 1, programDayId: 10, hour: 9, minute: 0),
        dayOfWeek: 2,
        programName: 'Сплит',
        dayNumber: 1,
      ),
      completes,
    );

    verifyNever(
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
    );
  });

  group('checkPermissions вне Android', () {
    setUp(() {
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);
    });

    test('оба разрешения не выданы независимо от расписания', () async {
      when(() => repository.allScheduled()).thenAnswer(
        (_) async => [
          ReminderSchedule(
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
          ),
        ],
      );

      final status = await service.checkPermissions();

      expect(status.notificationsEnabled, false);
      expect(status.exactAlarmsEnabled, false);
    });

    test(
      'статус не выводится из расписания — репозиторий не опрашивается',
      () async {
        when(
          () => repository.allScheduled(),
        ).thenThrow(StateError('allScheduled не должен вызываться'));

        final status = await service.checkPermissions();

        expect(status.notificationsEnabled, false);
        expect(status.exactAlarmsEnabled, false);
      },
    );
  });

  group('холодный старт из уведомления', () {
    setUp(() {
      registerFallbackValue(const InitializationSettings());
      // Сценарий Android: без Android-объекта плагина launch details не
      // читаются вовсе (47.15).
      registerFallbackValue(
        const AndroidNotificationChannel('workout_reminders', 'Канал'),
      );
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.createNotificationChannel(any()),
      ).thenAnswer((_) async {});
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
    });

    NotificationAppLaunchDetails launchDetails({
      required bool launched,
      String? payload,
    }) => NotificationAppLaunchDetails(
      launched,
      notificationResponse: payload == null
          ? null
          : NotificationResponse(
              notificationResponseType:
                  NotificationResponseType.selectedNotification,
              payload: payload,
            ),
    );

    test(
      'payload запуска доставляется, даже если обработчик ещё не назначен',
      () async {
        // Порядок боевого запуска: плагин инициализируется раньше, чем UI
        // успевает подписаться, поэтому payload обязан пережить это окно.
        when(
          () => plugin.getNotificationAppLaunchDetails(),
        ).thenAnswer((_) async => launchDetails(launched: true, payload: '42'));
        final tapped = <int>[];

        await service.initialize();
        expect(
          tapped,
          isEmpty,
          reason: 'обработчика ещё нет — payload в очереди',
        );

        service.onReminderTapped = tapped.add;

        expect(tapped, [42]);
      },
    );

    test('payload запуска сразу уходит назначенному обработчику', () async {
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => launchDetails(launched: true, payload: '7'));
      final tapped = <int>[];
      service.onReminderTapped = tapped.add;

      await service.initialize();

      expect(tapped, [7]);
    });

    test('обычный запуск без уведомления обработчик не трогает', () async {
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => launchDetails(launched: false, payload: '42'));
      final tapped = <int>[];
      service.onReminderTapped = tapped.add;

      await service.initialize();

      expect(tapped, isEmpty);
    });

    test(
      'вне Android launch details не читаются, ошибки нет (47.15)',
      () async {
        when(
          () => plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(null);
        // На Linux метод плагина не реализован — вызов бросил бы
        // `UnimplementedError` в лог при каждом старте desktop-сборки.
        when(
          () => plugin.getNotificationAppLaunchDetails(),
        ).thenThrow(UnimplementedError('getNotificationAppLaunchDetails'));
        final tapped = <int>[];
        service.onReminderTapped = tapped.add;

        await service.initialize();

        verifyNever(() => plugin.getNotificationAppLaunchDetails());
        expect(tapped, isEmpty);
        // Инициализация дошла до конца (иначе тест упал бы на исключении).
        verify(
          () => plugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).called(1);
      },
    );

    test('повторный initialize не дублирует доставку payload', () async {
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => launchDetails(launched: true, payload: '42'));
      final tapped = <int>[];
      service.onReminderTapped = tapped.add;

      await service.initialize();
      await service.initialize();

      expect(tapped, [42], reason: 'инициализация идемпотентна');
      verify(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).called(1);
    });

    test('битый payload при запуске не роняет инициализацию', () async {
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => launchDetails(launched: true, payload: 'abc'));
      final tapped = <int>[];
      service.onReminderTapped = tapped.add;

      await expectLater(service.initialize(), completes);
      expect(tapped, isEmpty);
    });

    test(
      'второй экземпляр сервиса в том же процессе не перечитывает payload',
      () async {
        // Сценарий импорта БД: контейнер пересоздан, ReminderService новый,
        // а launch Intent главной активности плагином не очищается. Повторное чтение
        // продублировало бы переход на уже открытый день.
        when(
          () => plugin.getNotificationAppLaunchDetails(),
        ).thenAnswer((_) async => launchDetails(launched: true, payload: '42'));
        final tapped = <int>[];
        service.onReminderTapped = tapped.add;
        await service.initialize();

        // Совершенно новый экземпляр с тем же плагином — как после импорта.
        final recreated = ReminderService(
          repository: repository,
          plugin: plugin,
        )..onReminderTapped = tapped.add;
        await recreated.initialize();

        expect(tapped, [42], reason: 'переход ровно один за процесс');
        verify(() => plugin.getNotificationAppLaunchDetails()).called(1);
      },
    );

    test('новый процесс снова читает launch details', () async {
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => launchDetails(launched: true, payload: '42'));
      final tapped = <int>[];
      service.onReminderTapped = tapped.add;
      await service.initialize();
      expect(tapped, [42]);

      // Новый запуск процесса — флаг сброшен, payload должен обработаться.
      resetLaunchDetailsForTests();
      final afterRestart = ReminderService(
        repository: repository,
        plugin: plugin,
      )..onReminderTapped = tapped.add;
      await afterRestart.initialize();

      expect(tapped, [42, 42]);
    });
  });

  group('диагностика разрешений на старте (48.7)', () {
    setUp(() {
      registerFallbackValue(const InitializationSettings());
      registerFallbackValue(
        const AndroidNotificationChannel('workout_reminders', 'Канал'),
      );
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.createNotificationChannel(any()),
      ).thenAnswer((_) async {});
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => NotificationAppLaunchDetails(false));
    });

    /// Перехватывает строки [debugPrint]: по логу на старте различаем
    /// «режим показа inexact» (стройка была без точных будильников) и
    /// «система не доставила» — читать его вручную негде, кроме logcat.
    Future<List<String>> captureLogs(Future<void> Function() body) async {
      final lines = <String>[];
      final previous = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        lines.add(message ?? '');
      };
      try {
        await body();
      } finally {
        debugPrint = previous;
      }
      return lines;
    }

    test('логирует режим показа при запуске', () async {
      when(
        () => android.areNotificationsEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => android.canScheduleExactNotifications(),
      ).thenAnswer((_) async => false);

      final lines = await captureLogs(service.initialize);

      expect(
        lines.any(
          (l) =>
              l.contains('Разрешения на старте: уведомления=true') &&
              l.contains('точные будильники=false'),
        ),
        isTrue,
        reason: 'по логу видно, что напоминание уйдёт с окном',
      );
      expect(lines.any((l) => l.contains('режим показа: inexact')), isTrue);
    });

    test('сбой чтения разрешений не роняет инициализацию', () async {
      when(
        () => android.areNotificationsEnabled(),
      ).thenThrow(StateError('канал не отвечает'));

      await expectLater(service.initialize(), completes);
    });
  });

  group('тап по уведомлению', () {
    test('payload передаётся обработчику сразу', () async {
      final tapped = <int>[];
      service.onReminderTapped = tapped.add;

      service.handleNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '42',
        ),
      );

      expect(tapped, [42]);
    });

    test('payload без числа игнорируется', () async {
      final tapped = <int>[];
      service.onReminderTapped = tapped.add;

      service.handleNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
        ),
      );
      service.handleNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'abc',
        ),
      );

      expect(tapped, isEmpty);
    });

    test('payload, пришедший до назначения обработчика, не теряется', () {
      final tapped = <int>[];

      service.handleNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '7',
        ),
      );
      expect(tapped, isEmpty);

      service.onReminderTapped = tapped.add;

      expect(tapped, [7]);
    });

    test('отложенный payload доставляется только один раз', () {
      final tapped = <int>[];
      service.handleNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '7',
        ),
      );

      service.onReminderTapped = tapped.add;
      service.onReminderTapped = tapped.add;

      expect(tapped, [7]);
    });
  });

  group('rescheduleAll при ошибке', () {
    test('ошибка одного дня не срывает перепланирование остальных', () async {
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(() => repository.allScheduled()).thenAnswer(
        (_) async => [
          ReminderSchedule(
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
          ),
          ReminderSchedule(
            reminder: const WorkoutReminder(
              id: 2,
              programDayId: 11,
              hour: 9,
              minute: 0,
              enabled: true,
            ),
            dayOfWeek: 3,
            programName: 'Бег',
            dayNumber: 1,
          ),
        ],
      );
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
      var first = true;
      when(() => android.areNotificationsEnabled()).thenAnswer((_) async {
        // Плагин падает на первом вызове — как это делает R8-сборка,
        // вырезавшая ресурсы уведомления.
        if (first) {
          first = false;
          throw PlatformException(code: 'invalid_resource');
        }
        return true;
      });

      await service.rescheduleAll();

      // Второй день всё равно запланирован.
      verify(
        () => plugin.zonedSchedule(
          id: 11,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });

  group('звук напоминаний (47.5)', () {
    late Directory tempDir;

    /// Реальный файл: сервис проверяет существование пути, иначе откатывается
    /// на встроенный сигнал.
    Future<File> soundFile([String name = 'beep.mp3']) async {
      final file = File('${tempDir.path}/$name');
      await file.writeAsBytes([1, 2, 3]);
      return file;
    }

    var channelFallbackRegistered = false;

    setUp(() async {
      if (!channelFallbackRegistered) {
        channelFallbackRegistered = true;
        registerFallbackValue(
          const AndroidNotificationChannel('workout_reminders', 'Канал'),
        );
      }
      tempDir = await Directory.systemTemp.createTemp('reminder_sound');
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.createNotificationChannel(any()),
      ).thenAnswer((_) async {});
      when(
        () => android.deleteNotificationChannel(
          channelId: any(named: 'channelId'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => android.areNotificationsEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => android.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
      when(
        () => repository.allScheduled(),
      ).thenAnswer((_) async => <ReminderSchedule>[]);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    /// Канал, созданный сервисом (последний аргумент `createNotificationChannel`).
    AndroidNotificationChannel createdChannel() {
      final channels = verify(
        () => android.createNotificationChannel(captureAny()),
      ).captured.cast<AndroidNotificationChannel>();
      return channels.last;
    }

    test('смена звука пересоздаёт канал и перепланирует напоминания', () async {
      final file = await soundFile();

      await service.applySoundSettings(enabled: true, filePath: file.path);

      final channel = createdChannel();
      expect(channel.sound, isA<UriAndroidNotificationSound>());
      expect(
        channel.sound!.sound,
        allOf(startsWith('file://'), contains('beep.mp3')),
      );
      expect(channel.playSound, isTrue);
      // Звук канала неизменен после создания — канал пересоздаётся.
      verify(
        () => android.deleteNotificationChannel(channelId: 'workout_reminders'),
      ).called(1);
      verify(() => repository.allScheduled()).called(1);
    });

    test('без файла канал возвращается к встроенному сигналу', () async {
      await service.applySoundSettings(enabled: true, filePath: null);

      final channel = createdChannel();
      expect(channel.sound, isA<RawResourceAndroidNotificationSound>());
      expect(
        (channel.sound! as RawResourceAndroidNotificationSound).sound,
        'notification',
      );
    });

    test(
      'удалённый файл не ломает уведомление (откат на raw-ресурс)',
      () async {
        final file = await soundFile();
        final path = file.path;
        await file.delete();

        await service.applySoundSettings(enabled: true, filePath: path);

        expect(
          createdChannel().sound,
          isA<RawResourceAndroidNotificationSound>(),
        );
      },
    );

    test('файл, недоступный системе, не уходит в канал (48.1)', () async {
      // Звук канала играет системный процесс: файл из приватного хранилища он
      // не прочитает и подменит стандартным сигналом. Поэтому канал должен
      // получить встроенный ресурс, а не недоступный URI.
      final file = await soundFile();

      await service.applySoundSettings(
        enabled: true,
        filePath: file.path,
        systemReadable: false,
      );

      final sound = createdChannel().sound;
      expect(sound, isA<RawResourceAndroidNotificationSound>());
      expect(
        (sound! as RawResourceAndroidNotificationSound).sound,
        'notification',
      );
    });

    test(
      'при загрузке настроек файл готовится, а флаг читается (48.1)',
      () async {
        registerFallbackValue(const InitializationSettings());
        when(
          () => plugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => plugin.getNotificationAppLaunchDetails(),
        ).thenAnswer((_) async => null);
        final file = await soundFile();
        final settings = _FakeSoundSettings()
          ..filePath = file.path
          ..systemReadable = false;
        final withSound = ReminderService(
          repository: repository,
          plugin: plugin,
          soundSettings: settings,
        );

        await withSound.initialize();

        // Подготовка вызвана — репозиторий успел перенести файл в доступное
        // системе хранилище; флаг прочитан и учтён в канале.
        expect(settings.ensureCalls, 1);
        expect(
          createdChannel().sound,
          isA<RawResourceAndroidNotificationSound>(),
        );
      },
    );

    test('выключенный звук оставляет канал без звука', () async {
      await service.applySoundSettings(enabled: false, filePath: null);

      final channel = createdChannel();
      expect(channel.playSound, isFalse);
      expect(channel.sound, isNull);
    });

    test('initialize создаёт канал с сохранённым файлом', () async {
      registerFallbackValue(const InitializationSettings());
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => plugin.getNotificationAppLaunchDetails(),
      ).thenAnswer((_) async => null);
      final file = await soundFile();
      final settings = _FakeSoundSettings()..filePath = file.path;
      final withSound = ReminderService(
        repository: repository,
        plugin: plugin,
        soundSettings: settings,
      );

      await withSound.initialize();

      expect(createdChannel().sound, isA<UriAndroidNotificationSound>());
    });

    test('уведомление планируется с выбранным звуком', () async {
      final file = await soundFile();
      when(() => repository.allScheduled()).thenAnswer(
        (_) async => [
          ReminderSchedule(
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
          ),
        ],
      );

      await service.applySoundSettings(enabled: true, filePath: file.path);

      final details =
          verify(
                () => plugin.zonedSchedule(
                  id: 10,
                  title: any(named: 'title'),
                  body: any(named: 'body'),
                  scheduledDate: any(named: 'scheduledDate'),
                  notificationDetails: captureAny(named: 'notificationDetails'),
                  androidScheduleMode: any(named: 'androidScheduleMode'),
                  matchDateTimeComponents: any(
                    named: 'matchDateTimeComponents',
                  ),
                  payload: any(named: 'payload'),
                ),
              ).captured.single
              as NotificationDetails;
      final androidDetails = details.android;
      expect(androidDetails, isNotNull);
      expect(androidDetails!.sound, isA<UriAndroidNotificationSound>());
    });
  });

  group('догон пропущенных напоминаний (47.6)', () {
    /// Журнал догона в памяти.
    _FakeCatchUpLog? log;

    /// Журнал системной доставки в памяти (48.8).
    _FakeDeliveredLog? delivered;

    ReminderSchedule scheduleOf(
      int programDayId, {
      required bool enabled,
      int? dayOfWeek,
      required int hour,
      required int minute,
    }) => ReminderSchedule(
      reminder: WorkoutReminder(
        id: programDayId,
        programDayId: programDayId,
        hour: hour,
        minute: minute,
        enabled: enabled,
      ),
      dayOfWeek: dayOfWeek,
      programName: 'Сплит',
      dayNumber: 1,
    );

    /// Время «минус [ago]» сегодня: удобный способ описать уже прошедшее
    /// напоминание, не подменяя системные часы.
    ///
    /// Час и минута берутся из `tz.local`, а не из `DateTime.now()`: сервис
    /// сравнивает их со временем в зоне напоминаний, а в тестах `tz.local` —
    /// UTC, и локальное время машины на этом сдвиге расходится на
    /// разницу часовых поясов.
    tz.TZDateTime todayAt(Duration ago) =>
        tz.TZDateTime.now(tz.local).subtract(ago);

    int todayWeekday() => tz.TZDateTime.now(tz.local).weekday;

    setUp(() {
      log = _FakeCatchUpLog();
      delivered = _FakeDeliveredLog();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.areNotificationsEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => android.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
      when(
        () => plugin.getActiveNotifications(),
      ).thenAnswer((_) async => <ActiveNotification>[]);
      when(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
      service = ReminderService(
        repository: repository,
        plugin: plugin,
        catchUpLog: log,
        deliveredLog: delivered,
      );
    });

    /// Одного напоминания с указанным временем (сегодня, сегодняшний день
    /// недели), если не задано иное.
    void onlyOne({
      int programDayId = 10,
      required bool enabled,
      int? dayOfWeek,
      required Duration ago,
    }) {
      final time = todayAt(ago);
      when(() => repository.allScheduled()).thenAnswer(
        (_) async => [
          scheduleOf(
            programDayId,
            enabled: enabled,
            dayOfWeek: dayOfWeek ?? todayWeekday(),
            hour: time.hour,
            minute: time.minute,
          ),
        ],
      );
    }

    /// Проверка, что догон-уведомление не показывалось.
    void verifyNotShown() {
      verifyNever(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      );
    }

    test('просроченное напоминание показывается сразу', () async {
      onlyOne(enabled: true, ago: const Duration(hours: 2));

      await service.catchUpMissed();

      // Тот же id и payload, что у обычного напоминания: тап ведёт в этот день.
      verify(
        () => plugin.show(
          id: 10,
          title: 'Сплит',
          body: 'Тренировка: день 1 (напоминание задержано системой)',
          notificationDetails: any(named: 'notificationDetails'),
          payload: '10',
        ),
      ).called(1);
      expect(log!.marked, [10]);
    });

    test(
      'время в пределах штатной задержки inexact не считается пропуском',
      () async {
        onlyOne(enabled: true, ago: const Duration(minutes: 5));

        await service.catchUpMissed();

        verifyNotShown();
      },
    );

    test('напоминание на будущее сегодня не показывается', () async {
      onlyOne(enabled: true, ago: const Duration(hours: -2));

      await service.catchUpMissed();

      verifyNotShown();
    });

    test('напоминание другого дня недели не показывается', () async {
      final time = todayAt(const Duration(hours: 2));
      final weekday = todayWeekday();
      final otherDay = weekday == 7 ? 1 : weekday + 1;
      when(() => repository.allScheduled()).thenAnswer(
        (_) async => [
          scheduleOf(
            10,
            enabled: true,
            dayOfWeek: otherDay,
            hour: time.hour,
            minute: time.minute,
          ),
        ],
      );

      await service.catchUpMissed();

      verifyNotShown();
    });

    test(
      'выключенное напоминание и день без привязки не показываются',
      () async {
        final time = todayAt(const Duration(hours: 2));
        when(() => repository.allScheduled()).thenAnswer(
          (_) async => [
            scheduleOf(
              10,
              enabled: false,
              dayOfWeek: todayWeekday(),
              hour: time.hour,
              minute: time.minute,
            ),
            scheduleOf(
              11,
              enabled: true,
              dayOfWeek: null,
              hour: time.hour,
              minute: time.minute,
            ),
          ],
        );

        await service.catchUpMissed();

        verifyNotShown();
      },
    );

    test('висящее в трее уведомление не дублируется', () async {
      onlyOne(enabled: true, ago: const Duration(hours: 2));
      when(() => plugin.getActiveNotifications()).thenAnswer(
        (_) async => const [
          ActiveNotification(id: 10, channelId: 'workout_reminders'),
        ],
      );

      await service.catchUpMissed();

      verifyNotShown();
    });

    test('в тот же день догон не повторяется', () async {
      onlyOne(enabled: true, ago: const Duration(hours: 2));
      log!.shownToday.add(10);

      await service.catchUpMissed();

      verifyNotShown();
    });

    test('вне Android догон ничего не делает', () async {
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);

      await service.catchUpMissed();

      verifyNever(() => repository.allScheduled());
    });

    test('ошибка показа не срывает остальные дни', () async {
      final time = todayAt(const Duration(hours: 2));
      when(() => repository.allScheduled()).thenAnswer(
        (_) async => [
          scheduleOf(
            10,
            enabled: true,
            dayOfWeek: todayWeekday(),
            hour: time.hour,
            minute: time.minute,
          ),
          scheduleOf(
            11,
            enabled: true,
            dayOfWeek: todayWeekday(),
            hour: time.hour,
            minute: time.minute,
          ),
        ],
      );
      var first = true;
      when(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {
        if (first) {
          first = false;
          throw PlatformException(code: 'boom');
        }
      });

      await service.catchUpMissed();

      expect(log!.marked, [11]);
      expect(log!.shownToday, [11], reason: 'отметка неудачного дня снята');
    });

    test(
      'день, открытый тапом по уведомлению, второй раз не показывается',
      () async {
        onlyOne(enabled: true, ago: const Duration(hours: 2));
        // Система уже доставила напоминание: пользователь тапнул по нему и
        // авто-снятие убрало уведомление из трея.
        await delivered!.markDelivered(10, DateTime.now());

        await service.catchUpMissed();

        verifyNotShown();
        expect(log!.marked, isEmpty);
      },
    );

    test('отметка доставки другого дня программы показу не мешает', () async {
      onlyOne(enabled: true, ago: const Duration(hours: 2));
      await delivered!.markDelivered(11, DateTime.now());

      await service.catchUpMissed();

      expect(log!.marked, [10]);
    });

    test('неудачный показ снимает отметку, повторный догоняет день', () async {
      onlyOne(enabled: true, ago: const Duration(hours: 2));
      var first = true;
      when(
        () => plugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {
        if (first) {
          first = false;
          throw PlatformException(code: 'boom');
        }
      });

      await service.catchUpMissed();

      expect(
        log!.marked,
        isEmpty,
        reason: 'после сбоя показа отметка снята — день не «сгорел»',
      );

      await service.catchUpMissed();

      expect(log!.marked, [10], reason: 'следующий прогон повторяет показ');
    });

    test('трей читается прямо перед показом каждого дня (48.8)', () async {
      final time = todayAt(const Duration(hours: 2));
      final weekday = todayWeekday();
      when(() => repository.allScheduled()).thenAnswer(
        (_) async => [
          for (final id in [10, 11])
            scheduleOf(
              id,
              enabled: true,
              dayOfWeek: weekday,
              hour: time.hour,
              minute: time.minute,
            ),
        ],
      );
      // Пока обрабатывается первый день, система «доставила» уведомление
      // второго: старое поведение читало трей один раз до цикла и показало бы
      // оба.
      var reads = 0;
      when(() => plugin.getActiveNotifications()).thenAnswer((_) async {
        reads++;
        return reads == 1
            ? <ActiveNotification>[]
            : const [
                ActiveNotification(id: 11, channelId: 'workout_reminders'),
              ];
      });

      await service.catchUpMissed();

      expect(log!.marked, [10]);
    });

    test(
      'параллельные вызовы догона схлопываются в один прогон (48.8)',
      () async {
        onlyOne(enabled: true, ago: const Duration(hours: 2));

        await Future.wait<void>([
          service.catchUpMissed(),
          service.catchUpMissed(),
        ]);

        verify(() => repository.allScheduled()).called(1);
        expect(log!.marked, [10]);
      },
    );

    test('догон дожидается незавершённой отметки доставки (48.8)', () async {
      onlyOne(enabled: true, ago: const Duration(hours: 2));
      delivered!.gate = Completer<void>();
      // Тап по уведомлению в фоне: отметка доставки ещё пишется в БД, а
      // возврат из фона уже запускает догон.
      final tap = service.handleNotificationResponse(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '10',
        ),
      );
      final catchUp = service.catchUpMissed();
      delivered!.gate!.complete();
      await Future.wait<void>([tap, catchUp]);

      verifyNotShown();
      expect(delivered!.delivered, [10]);
    });
  });

  group('catchUpDueTime (47.6)', () {
    final now = tz.TZDateTime(tz.local, 2026, 9, 29, 18, 0); // вторник

    tz.TZDateTime? due({
      int? dayOfWeek = 2,
      required int hour,
      required int minute,
    }) => ReminderService.catchUpDueTime(
      now,
      dayOfWeek: dayOfWeek,
      hour: hour,
      minute: minute,
    );

    test('час назад — пора догонять', () {
      expect(
        due(hour: 17, minute: 0),
        tz.TZDateTime(tz.local, 2026, 9, 29, 17, 0),
      );
    });

    test('ровно на границе порога — пора догонять', () {
      expect(
        due(hour: 17, minute: 45),
        tz.TZDateTime(tz.local, 2026, 9, 29, 17, 45),
      );
    });

    test('в пределах порога — ещё штатная задержка', () {
      expect(due(hour: 17, minute: 46), isNull);
    });

    test('время впереди — не показываем', () {
      expect(due(hour: 19, minute: 0), isNull);
    });

    test('другой день недели — не показываем', () {
      expect(due(dayOfWeek: 3, hour: 17, minute: 0), isNull);
    });

    test('день без привязки — не показываем', () {
      expect(due(dayOfWeek: null, hour: 17, minute: 0), isNull);
    });
  });

  test(
    'отзыв точного режима не оставляет день без напоминания (47.6)',
    () async {
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.areNotificationsEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => android.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
      var first = true;
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
      ).thenAnswer((_) async {
        if (first) {
          first = false;
          throw PlatformException(
            code: 'exact_alarms_not_permitted',
            message: 'Exact alarms are not permitted',
          );
        }
      });

      await service.schedule(
        const WorkoutReminder(
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

      final modes = verify(
        () => plugin.zonedSchedule(
          id: 10,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: captureAny(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
        ),
      ).captured;
      expect(modes, [
        AndroidScheduleMode.exactAllowWhileIdle,
        AndroidScheduleMode.inexactAllowWhileIdle,
      ]);
    },
  );

  group('напоминания ручных назначений (48.10)', () {
    late _MockPlanScheduleRepository planSchedule;
    late ReminderService manual;

    /// Назначение на дату в будущем с временем 18:30.
    late DateTime futureDate;

    /// Назначение для перепланирования: дата берётся от [futureDate],
    /// иначе после наступления даты планирование молча пропустилось бы.
    late PlanScheduleReminder item;

    setUp(() {
      final ahead = tz.TZDateTime.now(tz.local).add(const Duration(days: 3));
      futureDate = DateTime(ahead.year, ahead.month, ahead.day);
      item = PlanScheduleReminder(
        scheduleId: 5,
        programDayId: 42,
        scheduledDate: futureDate,
        hour: 18,
        minute: 30,
        programName: 'Тестовая',
        dayNumber: 3,
      );

      planSchedule = _MockPlanScheduleRepository();
      manual = ReminderService(
        repository: repository,
        plugin: plugin,
        planSchedule: planSchedule,
      );
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.areNotificationsEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => android.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
    });

    test('scheduleManualReminder планирует уведомление дня', () async {
      await manual.scheduleManualReminder(
        scheduleId: item.scheduleId,
        programDayId: item.programDayId,
        date: futureDate,
        hour: 18,
        minute: 30,
        programName: item.programName,
        dayNumber: item.dayNumber,
      );

      verify(
        () => plugin.zonedSchedule(
          id: ReminderService.manualReminderIdBase + 5,
          title: 'Тестовая',
          body: 'Тренировка: день 3',
          scheduledDate: tz.TZDateTime(
            tz.local,
            futureDate.year,
            futureDate.month,
            futureDate.day,
            18,
            30,
          ),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          // Одноразовое уведомление: без привязки к дню недели.
          matchDateTimeComponents: null,
          payload: 'm:5:42',
        ),
      ).called(1);
    });

    test('прошедшее время назначения не планируется', () async {
      await manual.scheduleManualReminder(
        scheduleId: item.scheduleId,
        programDayId: item.programDayId,
        date: DateTime(2020, 1, 1),
        hour: 10,
        minute: 0,
        programName: item.programName,
        dayNumber: item.dayNumber,
      );

      verifyNever(
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
      );
    });

    test('cancelManualReminder отменяет по id назначения', () async {
      await manual.cancelManualReminder(item.scheduleId);

      verify(
        () => plugin.cancel(id: ReminderService.manualReminderIdBase + 5),
      ).called(1);
    });

    test('rescheduleDays перевзвешивает ручные назначения дней', () async {
      when(() => repository.scheduledForDays([42])).thenAnswer((_) async => []);
      when(
        () => planSchedule.remindersForDays([42]),
      ).thenAnswer((_) async => [item]);

      await manual.rescheduleDays([42]);

      verify(
        () => plugin.zonedSchedule(
          id: ReminderService.manualReminderIdBase + 5,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('cancelDays снимает ручные назначения дней', () async {
      when(
        () => planSchedule.remindersForDays([42]),
      ).thenAnswer((_) async => [item]);

      await manual.cancelDays([42]);

      verify(
        () => plugin.cancel(id: ReminderService.manualReminderIdBase + 5),
      ).called(1);
    });

    test(
      'rescheduleAll перевзвешивает ручные назначения в горизонте',
      () async {
        when(() => repository.allScheduled()).thenAnswer((_) async => []);
        when(
          () => planSchedule.remindersBetween(any(), any()),
        ).thenAnswer((_) async => [item]);

        await manual.rescheduleAll();

        verify(
          () => plugin.zonedSchedule(
            id: ReminderService.manualReminderIdBase + 5,
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
            payload: any(named: 'payload'),
          ),
        ).called(1);
      },
    );

    test('тап по ручному уведомлению не пишет отметку доставки', () async {
      final deliveredLog = _FakeDeliveredLog();
      final tapService = ReminderService(
        repository: repository,
        plugin: plugin,
        deliveredLog: deliveredLog,
      );
      final tapped = <int>[];
      tapService.onReminderTapped = tapped.add;

      await tapService.handleNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'm:5:42',
        ),
      );

      expect(tapped, [42]);
      expect(
        deliveredLog.delivered,
        isEmpty,
        reason: 'тап по ручному не доказывает показ еженедельного (48.8)',
      );

      // Контраст: голый payload еженедельного уведомления отметку ставит.
      await tapService.handleNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '42',
        ),
      );

      expect(deliveredLog.delivered, contains(42));
    });
  });
}

/// Хранилище настроек звука напоминаний для [ReminderService] (47.5).
class _FakeSoundSettings extends SoundSettingsStore {
  bool enabled = true;
  String? filePath;

  /// Доступен ли файл системному процессу (48.1).
  bool systemReadable = true;

  /// Сколько раз вызывалась подготовка файла при загрузке настроек (48.1).
  int ensureCalls = 0;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<String?> soundFilePath() async => filePath;

  @override
  Future<void> setEnabled(bool value) async => enabled = value;

  @override
  Future<void> setSoundFile(String? path) async => filePath = path;

  @override
  Future<bool> isSoundSystemReadable() async => systemReadable;

  @override
  Future<void> ensureSoundFileReady() async => ensureCalls++;
}

/// Журнал догона пропущенных напоминаний в памяти (47.6).
class _FakeCatchUpLog implements ReminderCatchUpLog {
  /// Дни программы, для которых догон уже показывали сегодня.
  final Set<int> shownToday = <int>{};

  /// Дни программы, отмеченные журналом (в порядке показа).
  final List<int> marked = <int>[];

  @override
  Future<bool> wasShownOn(int programDayId, DateTime day) async =>
      shownToday.contains(programDayId);

  @override
  Future<void> markShown(int programDayId, DateTime at) async {
    shownToday.add(programDayId);
    marked.add(programDayId);
  }

  @override
  Future<void> unmarkShown(int programDayId) async {
    shownToday.remove(programDayId);
    marked.remove(programDayId);
  }
}

/// Журнал системной доставки в памяти (48.8).
class _FakeDeliveredLog implements ReminderDeliveredLog {
  /// Дни, по которым пришёл тап по системному уведомлению.
  final Set<int> delivered = <int>{};

  /// Если задан, запись отметки ждёт её — для проверки гонки
  /// «тап в фоне ↔ догон при возврате».
  Completer<void>? gate;

  @override
  Future<bool> wasDeliveredOn(int programDayId, DateTime day) async =>
      delivered.contains(programDayId);

  @override
  Future<void> markDelivered(int programDayId, DateTime at) async {
    final pending = gate;
    if (pending != null && !pending.isCompleted) {
      await pending.future;
    }
    delivered.add(programDayId);
  }
}
