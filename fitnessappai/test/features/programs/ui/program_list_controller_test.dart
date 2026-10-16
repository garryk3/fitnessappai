// ignore_for_file: type=lint
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/data/data_change_notifier.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_list_controller.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

/// Сервис напоминаний, который только записывает вызовы (плагин не нужен).
class _RecordingReminderService extends ReminderService {
  _RecordingReminderService(WorkoutReminderRepository repository)
    : super(repository: repository);

  final List<List<int>> rescheduledDays = [];
  final List<List<int>> cancelledDays = [];
  final List<int> deletedDayIds = [];

  @override
  Future<void> rescheduleDays(Iterable<int> programDayIds) async {
    rescheduledDays.add(programDayIds.toList()..sort());
  }

  @override
  Future<void> cancelDays(Iterable<int> programDayIds) async {
    cancelledDays.add(programDayIds.toList()..sort());
  }

  @override
  Future<void> cancel(int programDayId) async {
    deletedDayIds.add(programDayId);
  }
}

void main() {
  late AppDatabase db;
  late ProgramRepository programRepository;
  late WorkoutReminderRepository reminderRepository;
  late _RecordingReminderService reminders;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    programRepository = ProgramRepository(db);
    reminderRepository = WorkoutReminderRepository(db);
    reminders = _RecordingReminderService(reminderRepository);
  });

  tearDown(() async {
    await db.close();
  });

  Future<ProgramDay> createDay({int? dayOfWeek = 2}) async {
    final program = await programRepository.create(
      Program(
        name: 'Сплит',
        daysCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: dayOfWeek)],
    );
    return (await programRepository.getDays(program.id!)).single;
  }

  /// Контроллер с собственным `DataChangeNotifier`: мутации программы шлют
  /// глобальный нотификатор, и его фоновая перезагрузка не должна бить по
  /// закрытой БД в tearDown. Начальная загрузка дожидается явно.
  Future<ProgramListController> createController({
    WorkoutRepository? workoutRepository,
    DateTime Function()? clock,
  }) async {
    final changes = DataChangeNotifier();
    final controller = ProgramListController(
      programRepository,
      changes: changes,
      reminderService: reminders,
      workoutRepository: workoutRepository,
      clock: clock,
    );
    await controller.refresh();
    addTearDown(() {
      controller.dispose();
      changes.dispose();
    });
    return controller;
  }

  group(
    'ProgramListController: активность программы и напоминания (47.8, 2г)',
    () {
      test('деактивация отменяет уведомления дней программы', () async {
        final day = await createDay();
        final controller = await createController();

        await controller.deactivate(day.programId);

        expect(reminders.cancelledDays, [
          [day.id!],
        ]);
        expect(reminders.rescheduledDays, isEmpty);
        final program = await programRepository.getProgram(day.programId);
        expect(program!.program.deactivatedAt, isNotNull);
      });

      test('активация перепланирует сохранённые напоминания', () async {
        final day = await createDay();
        await reminderRepository.saveForDay(
          day.id!,
          hour: 9,
          minute: 0,
          enabled: true,
        );
        final controller = await createController();

        await controller.setActive(day.programId);

        expect(reminders.rescheduledDays, [
          [day.id!],
        ]);
        expect(reminders.cancelledDays, isEmpty);
        final program = await programRepository.getProgram(day.programId);
        expect(program!.program.deactivatedAt, isNull);
      });

      test(
        'настройки напоминаний переживают деактивацию и активацию',
        () async {
          final day = await createDay();
          await reminderRepository.saveForDay(
            day.id!,
            hour: 9,
            minute: 0,
            enabled: true,
          );
          final controller = await createController();

          await controller.deactivate(day.programId);
          expect(await reminderRepository.getForDay(day.id!), isNotNull);

          await controller.setActive(day.programId);
          expect((await reminderRepository.getForDay(day.id!))!.hour, 9);
        },
      );

      test(
        'деактивация и активация другой программы не трогают её дни',
        () async {
          final first = await createDay();
          final second = await createDay();
          final controller = await createController();

          await controller.deactivate(first.programId);
          await controller.setActive(second.programId);

          expect(reminders.cancelledDays, [
            [first.id!],
          ]);
          expect(reminders.rescheduledDays, [
            [second.id!],
          ]);
        },
      );

      test('удаление программы по-прежнему отменяет уведомления', () async {
        final day = await createDay();
        final controller = await createController();

        await controller.deleteProgram(day.programId);

        expect(reminders.deletedDayIds, [day.id!]);
        expect(reminders.cancelledDays, isEmpty);
      });
    },
  );

  group('ProgramListController: недельный прогресс карточек (54.4)', () {
    // «Сегодня» — среда 2026-10-14: текущая неделя [12.10, 19.10).
    final today = DateTime(2026, 10, 14);

    Future<WorkoutRepository> saveSession({
      required int programId,
      required int? programDayId,
      required DateTime performedDate,
    }) async {
      final repository = WorkoutRepository(db);
      await repository.saveSession(
        WorkoutSession(
          programId: programId,
          programName: 'Сплит',
          programDayId: programDayId,
          dayIndex: 0,
          performedDate: performedDate,
          startedAt: performedDate.add(const Duration(hours: 18)),
          endedAt: performedDate.add(const Duration(hours: 18, minutes: 40)),
        ),
        [
          WorkoutSetResult(
            sessionId: 0,
            exerciseName: 'Жим',
            exerciseType: ExerciseType.strength,
            setIndex: 1,
            reps: 10,
            completedAt: performedDate.add(const Duration(minutes: 5)),
          ),
        ],
      );
      return repository;
    }

    test('привязанный день со сессией этой недели → 1/1, 100%', () async {
      final day = await createDay(dayOfWeek: 2);
      final repository = await saveSession(
        programId: day.programId,
        programDayId: day.id,
        performedDate: DateTime(2026, 10, 13),
      );
      final controller = await createController(
        workoutRepository: repository,
        clock: () => today,
      );

      final item = controller.items.value.single;
      expect(item.weekProgress, (performed: 1, assigned: 1));
      expect(item.weekPercent, 100);
    });

    test('сессия прошлой недели не засчитывается', () async {
      final day = await createDay(dayOfWeek: 2);
      final repository = await saveSession(
        programId: day.programId,
        programDayId: day.id,
        performedDate: DateTime(2026, 10, 5),
      );
      final controller = await createController(
        workoutRepository: repository,
        clock: () => today,
      );

      final item = controller.items.value.single;
      expect(item.weekProgress, (performed: 0, assigned: 1));
    });

    test('непривязанные дни: сессии по programId, дни — знаменатель', () async {
      final first = await createDay(dayOfWeek: null);
      final second = await createDay(dayOfWeek: null);
      final repository = await saveSession(
        programId: first.programId,
        programDayId: first.id,
        performedDate: DateTime(2026, 10, 13),
      );
      final controller = await createController(
        workoutRepository: repository,
        clock: () => today,
      );

      final firstItem = controller.items.value.firstWhere(
        (item) => item.program.id == first.programId,
      );
      expect(firstItem.weekProgress, (performed: 1, assigned: 1));

      final secondItem = controller.items.value.firstWhere(
        (item) => item.program.id == second.programId,
      );
      expect(secondItem.weekProgress, (performed: 0, assigned: 1));
    });

    test('без WorkoutRepository прогресс не считается', () async {
      await createDay(dayOfWeek: 2);
      final controller = await createController(clock: () => today);

      final item = controller.items.value.single;
      expect(item.weekProgress, isNull);
      expect(item.weekPercent, isNull);
    });
  });
}
