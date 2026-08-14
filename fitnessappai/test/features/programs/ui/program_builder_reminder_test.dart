import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_builder_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

class _MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late AppDatabase db;
  late ProgramRepository repository;
  late ExerciseRepository exerciseRepository;
  late WorkoutReminderRepository reminderRepository;
  late _MockNotificationsPlugin plugin;
  late ReminderService reminderService;

  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(tz.TZDateTime(tz.local, 2024, 1, 1));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.exact);
    registerFallbackValue('');
  });

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repository = ProgramRepository(db);
    exerciseRepository = ExerciseRepository(db, MediaStore());
    reminderRepository = WorkoutReminderRepository(db);
    plugin = _MockNotificationsPlugin();
    reminderService = ReminderService(
      repository: reminderRepository,
      plugin: plugin,
    );
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
    locator.reset();
    locator.registerLazySingleton<WorkoutReminderRepository>(
      () => reminderRepository,
    );
    locator.registerLazySingleton<ReminderService>(() => reminderService);
    addTearDown(() => db.close());
  });

  Future<void> pumpBuilder(WidgetTester tester, {int? programId}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ProgramBuilderScreen(
          repository: repository,
          programId: programId,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterName(WidgetTester tester, String name) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Название'),
      name,
    );
  }

  Future<void> setWeekday(WidgetTester tester, String day) async {
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(day).last);
    await tester.pumpAndSettle();
  }

  Program program(String name, {int daysCount = 1}) {
    return Program(
      name: name,
      daysCount: daysCount,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Создаёт программу на 1 день с основным упражнением (валидную для
  /// сохранения) и возвращает её id.
  Future<int> createValidProgram() async {
    final exercise = await exerciseRepository.create(
      Exercise(
        name: 'Жим штанги',
        type: ExerciseType.strength,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      const [],
    );
    final created = await repository.create(program('Сплит'), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    final day = (await repository.getDays(created.id!)).single;
    await repository.addExerciseToDay(day.id!, exercise.id!);
    return created.id!;
  }

  Future<int> createDay({int? dayOfWeek, int hour = 9, int minute = 0}) async {
    final programId = await createValidProgram();
    final day = (await repository.getDays(programId)).single;
    if (dayOfWeek != null) {
      await reminderRepository.saveForDay(
        day.id!,
        hour: hour,
        minute: minute,
        enabled: true,
      );
    }
    return day.id!;
  }

  testWidgets('диалог: без дня недели переключатель напоминания недоступен', (
    tester,
  ) async {
    await pumpBuilder(tester);
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    final tile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Напоминать'),
    );
    expect(tile.value, isFalse);
    expect(tile.onChanged, isNull);
  });

  testWidgets(
    'создание программы: включение напоминания планирует уведомление',
    (tester) async {
      final programId = await createValidProgram();
      await pumpBuilder(tester, programId: programId);
      await enterName(tester, 'Сплит');

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await setWeekday(tester, 'Пн');
      await tester.tap(find.text('Напоминать'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').first);
      await tester.pumpAndSettle();

      final scheduled = await reminderRepository.allScheduled();
      expect(scheduled, hasLength(1));
      expect(scheduled.single.dayOfWeek, 1);
      expect(scheduled.single.reminder.hour, 9);
      expect(scheduled.single.reminder.minute, 0);
      verify(
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
      ).called(1);
    },
  );

  testWidgets('редактирование: выключение напоминания отменяет уведомление', (
    tester,
  ) async {
    final dayId = await createDay(dayOfWeek: 3, hour: 18, minute: 45);
    await pumpBuilder(
      tester,
      programId: (await repository.getPrograms()).single.program.id,
    );

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('18:45'), findsOneWidget);

    await tester.tap(find.text('Напоминать'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').first);
    await tester.pumpAndSettle();

    expect(await reminderRepository.allScheduled(), isEmpty);
    verify(() => plugin.cancel(id: dayId)).called(1);
  });

  testWidgets('редактирование: сохранённое время показывается в диалоге', (
    tester,
  ) async {
    await createDay(dayOfWeek: 2, hour: 18, minute: 45);
    final programId = (await repository.getPrograms()).single.program.id!;
    await pumpBuilder(tester, programId: programId);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    final tile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Напоминать'),
    );
    expect(tile.value, isTrue);
    expect(find.text('18:45'), findsOneWidget);
  });

  testWidgets('создание программы: без включения напоминание не создаётся', (
    tester,
  ) async {
    final programId = await createValidProgram();
    await pumpBuilder(tester, programId: programId);
    await enterName(tester, 'Сплит');

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await setWeekday(tester, 'Вт');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить').first);
    await tester.pumpAndSettle();

    expect(await reminderRepository.allScheduled(), isEmpty);
    verifyNever(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
      ),
    );
  });
}
