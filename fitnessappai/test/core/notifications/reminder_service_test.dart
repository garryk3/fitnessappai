import 'package:flutter/services.dart';
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
  // initialize() ходит в FlutterTimezone через method channel — нужен binding.
  TestWidgetsFlutterBinding.ensureInitialized();
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
}
