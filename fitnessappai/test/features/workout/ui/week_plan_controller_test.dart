import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';

void main() {
  late AppDatabase db;
  late WeekPlanController controller;
  late ProgramRepository programRepo;
  late PlanScheduleRepository scheduleRepo;

  DateTime fixedNow() => DateTime(2026, 8, 10);

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    programRepo = ProgramRepository(db);
    scheduleRepo = PlanScheduleRepository(db);
    controller = WeekPlanController(
      programRepository: programRepo,
      workoutRepository: WorkoutRepository(db),
      planScheduleRepository: scheduleRepo,
      clock: fixedNow,
    );
  });

  tearDown(() async {
    // Конструктор контроллера запускает загрузку без await — дожидаемся её
    // перед закрытием БД, иначе запросы падают на закрытом соединении.
    await pumpEventQueue();
    controller.dispose();
    await db.close();
  });

  Future<int> createUnlinkedDay() async {
    final program = await programRepo.create(
      Program(
        name: 'Без привязки',
        daysCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isActive: true,
        activatedAt: DateTime(2024, 1, 1),
      ),
      [const ProgramDay(programId: 0, dayIndex: 0)],
    );
    final days = await programRepo.getDays(program.id!);
    return days.first.id!;
  }

  Future<int> createLinkedDay(int dayOfWeek) async {
    final program = await programRepo.create(
      Program(
        name: 'По расписанию',
        daysCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isActive: true,
        activatedAt: DateTime(2024, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: dayOfWeek)],
    );
    final days = await programRepo.getDays(program.id!);
    return days.first.id!;
  }

  test('manual schedule appears in items', () async {
    final dayId = await createUnlinkedDay();
    await scheduleRepo.schedule(dayId, DateTime(2026, 8, 15));

    controller.viewMode.value = PlanViewMode.month;
    controller.monthStart.value = DateTime(2026, 8, 1);
    await controller.refresh();

    final items = controller.items.value;
    final matching = items.where(
      (i) => i.programDayId == dayId && i.scheduledDate.day == 15,
    );
    expect(matching, hasLength(1));
    expect(matching.first.status, WeekPlanStatus.pending);
  });

  test('cancelSchedule removes manual entry', () async {
    final dayId = await createUnlinkedDay();
    await scheduleRepo.schedule(dayId, DateTime(2026, 8, 15));

    controller.viewMode.value = PlanViewMode.month;
    controller.monthStart.value = DateTime(2026, 8, 1);
    await controller.refresh();
    expect(controller.items.value, isNotEmpty);

    await controller.cancelSchedule(dayId, DateTime(2026, 8, 15));
    final items = controller.items.value;
    final matching = items.where(
      (i) => i.programDayId == dayId && i.scheduledDate.day == 15,
    );
    expect(matching, isEmpty);
  });

  test('scheduleDay adds to items', () async {
    final dayId = await createUnlinkedDay();

    controller.viewMode.value = PlanViewMode.month;
    controller.monthStart.value = DateTime(2026, 9, 1);
    await controller.refresh();

    // Unlinked day shows on today (Aug 10), but not Sept 20.
    final beforeItems = controller.items.value
        .where(
          (i) =>
              i.programDayId == dayId &&
              i.scheduledDate.month == 9 &&
              i.scheduledDate.day == 20,
        )
        .toList();
    expect(beforeItems, isEmpty);

    await controller.scheduleDay(dayId, DateTime(2026, 9, 20));
    final items = controller.items.value.where(
      (i) =>
          i.programDayId == dayId &&
          i.scheduledDate.month == 9 &&
          i.scheduledDate.day == 20,
    );
    expect(items, hasLength(1));
  });

  test('manual schedule does not duplicate recurring item', () async {
    // Monday = 1, Aug 10 2026 is a Monday.
    final dayId = await createLinkedDay(1);

    // Manually schedule on the same date as the recurring.
    await scheduleRepo.schedule(dayId, DateTime(2026, 8, 10));

    controller.viewMode.value = PlanViewMode.week;
    controller.weekStart.value = DateTime(2026, 8, 10);
    await controller.refresh();

    final items = controller.items.value.where(
      (i) =>
          i.programDayId == dayId &&
          i.scheduledDate.day == 10 &&
          i.scheduledDate.month == 8,
    );
    expect(items, hasLength(1));
  });

  test('навигация плана ограничена ±1 неделей и ±1 месяцем', () async {
    await controller.refresh();
    // Текущий период — неделя с 10.08.2026, месяц август 2026.
    expect(controller.canGoPrevWeek, isTrue);
    expect(controller.canGoNextWeek, isTrue);
    expect(controller.canGoPrevMonth, isTrue);
    expect(controller.canGoNextMonth, isTrue);

    controller.weekStart.value = DateTime(2026, 8, 17);
    controller.monthStart.value = DateTime(2026, 9, 1);
    expect(controller.canGoNextWeek, isFalse);
    expect(controller.canGoPrevWeek, isTrue);
    expect(controller.canGoNextMonth, isFalse);
    expect(controller.canGoPrevMonth, isTrue);

    controller.weekStart.value = DateTime(2026, 8, 3);
    controller.monthStart.value = DateTime(2026, 7, 1);
    expect(controller.canGoPrevWeek, isFalse);
    expect(controller.canGoNextWeek, isTrue);
    expect(controller.canGoPrevMonth, isFalse);
    expect(controller.canGoNextMonth, isTrue);

    // Дальше границы нельзя: флаги остаются заблокированными.
    controller.weekStart.value = DateTime(2026, 8, 24);
    expect(controller.canGoNextWeek, isFalse);
  });

  group('набор действий дня (47.1)', () {
    final today = DateTime(2026, 8, 10);

    WeekPlanItem item({
      required DateTime scheduledDate,
      required WeekPlanStatus status,
      int? dayOfWeek = 1,
      bool isManual = false,
    }) => WeekPlanItem(
      programDayId: 1,
      dayIndex: 0,
      programName: 'База',
      dayOfWeek: dayOfWeek,
      scheduledDate: scheduledDate,
      status: status,
      isManual: isManual,
    );

    test('кастомное назначение — только удаление', () {
      final scheduled = item(
        scheduledDate: today,
        status: WeekPlanStatus.pending,
        dayOfWeek: null,
        isManual: true,
      );

      expect(dayActionsFor(scheduled, today), {DayAction.remove});
    });

    test('кастомное назначение на будущий день — тоже только удаление', () {
      final scheduled = item(
        scheduledDate: DateTime(2026, 8, 13),
        status: WeekPlanStatus.pending,
        dayOfWeek: null,
        isManual: true,
      );

      expect(dayActionsFor(scheduled, today), {DayAction.remove});
    });

    test(
      'непривязанный день программы — не «кастомный», есть старт и пропуск',
      () {
        // Такой день показывается на «сегодня» автоматически, строки в
        // plan_schedule не имеет — удалять его нечем.
        final unlinked = item(
          scheduledDate: today,
          status: WeekPlanStatus.pending,
          dayOfWeek: null,
        );

        expect(dayActionsFor(unlinked, today), {
          DayAction.start,
          DayAction.skip,
        });
      },
    );

    test('тренировка программы сегодня — старт и пропуск', () {
      final scheduled = item(
        scheduledDate: today,
        status: WeekPlanStatus.pending,
      );

      expect(dayActionsFor(scheduled, today), {
        DayAction.start,
        DayAction.skip,
      });
    });

    test(
      'тренировка программы в другой день — только перенос, без пропуска',
      () {
        final scheduled = item(
          scheduledDate: DateTime(2026, 8, 13),
          status: WeekPlanStatus.pending,
        );

        expect(dayActionsFor(scheduled, today), {DayAction.reschedule});
      },
    );

    test('пропуск тренировки сегодня отменяется, вчерашнего — нет', () {
      final skippedToday = item(
        scheduledDate: today,
        status: WeekPlanStatus.skipped,
      );
      final skippedYesterday = item(
        scheduledDate: DateTime(2026, 8, 9),
        status: WeekPlanStatus.skipped,
      );

      expect(dayActionsFor(skippedToday, today), {DayAction.unskip});
      expect(dayActionsFor(skippedYesterday, today), isEmpty);
    });

    test('выполненная и устаревшая тренировка действий не имеют', () {
      for (final status in [
        WeekPlanStatus.performed,
        WeekPlanStatus.rescheduled,
        WeekPlanStatus.pastSkipped,
      ]) {
        expect(
          dayActionsFor(item(scheduledDate: today, status: status), today),
          isEmpty,
          reason: '$status',
        );
      }
    });
  });

  test(
    'пропуск тренировки сегодня работает при «чужой» сессии в неделе',
    () async {
      // Регресс 43.7: сессия того же programDayId за прошлый день в этой неделе
      // не должна мешать пропуску сегодняшнего вхождения.
      final dayId = await createLinkedDay(DateTime.monday);
      final foreign = await programRepo.getDay(dayId);
      await WorkoutRepository(db).saveSession(
        WorkoutSession(
          programName: 'По расписанию',
          programDayId: foreign!.id,
          dayIndex: foreign.dayIndex,
          performedDate: DateTime(2026, 8, 9),
          startedAt: DateTime(2026, 8, 9),
          endedAt: DateTime(2026, 8, 9, 0, 40),
        ),
        const [],
      );
      await controller.refresh();

      final today10 = controller.items.value.firstWhere(
        (i) => i.scheduledDate.day == 10 && i.scheduledDate.month == 8,
      );
      expect(today10.status, WeekPlanStatus.pending);

      await controller.markSkipped(today10);

      final skipped = controller.items.value.firstWhere(
        (i) => i.scheduledDate.day == 10 && i.scheduledDate.month == 8,
      );
      expect(skipped.status, WeekPlanStatus.skipped);
      expect(dayActionsFor(skipped, fixedNow()), {DayAction.unskip});
    },
  );

  test('ручное назначение помечается isManual, дни программы — нет', () async {
    final linkedId = await createLinkedDay(DateTime.thursday);
    final unlinkedId = await createUnlinkedDay();
    await scheduleRepo.schedule(linkedId, DateTime(2026, 8, 14));
    controller.weekStart.value = DateTime(2026, 8, 10);
    await controller.refresh();

    final manual = controller.items.value.firstWhere(
      (i) => i.programDayId == linkedId && i.scheduledDate.day == 14,
    );
    final recurrent = controller.items.value.firstWhere(
      (i) => i.programDayId == linkedId && i.scheduledDate.day == 13,
    );
    final unlinked = controller.items.value.firstWhere(
      (i) => i.programDayId == unlinkedId,
    );

    expect(manual.isManual, isTrue);
    expect(recurrent.isManual, isFalse);
    expect(unlinked.isManual, isFalse);
    expect(unlinked.scheduledDate, DateTime(2026, 8, 10));
  });

  group('окно переноса — только в рамках тренировочной недели (47.2)', () {
    Future<WeekPlanItem> itemOn(DateTime now, int dayOfWeek) async {
      // 10.08.2026 — понедельник.
      final dayId = await createLinkedDay(dayOfWeek);
      controller.dispose();
      controller = WeekPlanController(
        programRepository: programRepo,
        workoutRepository: WorkoutRepository(db),
        planScheduleRepository: scheduleRepo,
        clock: () => now,
      );
      controller.weekStart.value = DateTime(2026, 8, 10);
      await controller.refresh();
      return controller.items.value.firstWhere(
        (i) =>
            i.programDayId == dayId &&
            i.scheduledDate.day == 10 + dayOfWeek - 1,
      );
    }

    test(
      'прошедший день своей недели ещё можно перенести на сегодня',
      () async {
        // Воскресенье: понедельник той же недели — перенос доступен.
        final item = await itemOn(DateTime(2026, 8, 16), DateTime.monday);

        expect(item.status, WeekPlanStatus.pending);
        expect(dayActionsFor(item, DateTime(2026, 8, 16)), {
          DayAction.reschedule,
        });
      },
    );

    test(
      'в следующий понедельник понедельник прошлой недели — переноса нет',
      () async {
        final item = await itemOn(DateTime(2026, 8, 17), DateTime.monday);

        expect(item.status, WeekPlanStatus.pastSkipped);
        expect(dayActionsFor(item, DateTime(2026, 8, 17)), isEmpty);
      },
    );

    test(
      'последний день недели (воскресенье) в понедельник — уже неделя',
      () async {
        // 16.08 — воскресенье, тренировка «сегодня» (старт + пропуск);
        // 17.08 — понедельник следующей недели: переноса уже нет.
        final sunday = await itemOn(DateTime(2026, 8, 16), DateTime.sunday);
        expect(sunday.status, WeekPlanStatus.pending);
        expect(dayActionsFor(sunday, DateTime(2026, 8, 16)), {
          DayAction.start,
          DayAction.skip,
        });

        controller.dispose();
        controller = WeekPlanController(
          programRepository: programRepo,
          workoutRepository: WorkoutRepository(db),
          planScheduleRepository: scheduleRepo,
          clock: () => DateTime(2026, 8, 17),
        );
        controller.weekStart.value = DateTime(2026, 8, 10);
        await controller.refresh();
        final sundayNextMonday = controller.items.value.firstWhere(
          (i) =>
              i.programName == 'По расписанию' &&
              i.scheduledDate.day == 16 &&
              i.scheduledDate.month == 8,
        );
        expect(sundayNextMonday.status, WeekPlanStatus.pastSkipped);
        expect(dayActionsFor(sundayNextMonday, DateTime(2026, 8, 17)), isEmpty);
      },
    );
  });

  group('перенос очищает день-источник (47.3)', () {
    // Программа из двух дней: понедельник и вторник одной недели.
    Future<List<int>> createTwoDayProgram() async {
      final program = await programRepo.create(
        Program(
          name: 'Два дня',
          daysCount: 2,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isActive: true,
          activatedAt: DateTime(2024, 1, 1),
        ),
        [
          ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: DateTime.monday),
          ProgramDay(programId: 0, dayIndex: 1, dayOfWeek: DateTime.tuesday),
        ],
      );
      final days = await programRepo.getDays(program.id!);
      return days.map((d) => d.id!).toList();
    }

    test('после переноса вторника понедельник остаётся в плане', () async {
      final ids = await createTwoDayProgram();
      controller.weekStart.value = DateTime(2026, 8, 10);
      await controller.refresh();

      final tuesday = controller.items.value.firstWhere(
        (i) => i.programDayId == ids[1] && i.scheduledDate.day == 11,
      );
      await controller.markRescheduled(tuesday);

      final visible = controller.items.value
          .where((i) => i.scheduledDate.day == 11)
          .toList();
      expect(visible, isEmpty);
      // Понедельник той же недели не тронут.
      expect(
        controller.items.value.any(
          (i) => i.programDayId == ids[0] && i.scheduledDate.day == 10,
        ),
        isTrue,
      );
    });

    test('на следующей неделе тренировка снова в плане', () async {
      final ids = await createTwoDayProgram();
      controller.weekStart.value = DateTime(2026, 8, 10);
      await controller.refresh();

      final monday = controller.items.value.firstWhere(
        (i) => i.programDayId == ids[0] && i.scheduledDate.day == 10,
      );
      await controller.markRescheduled(monday);
      expect(
        controller.items.value.any(
          (i) => i.programDayId == ids[0] && i.scheduledDate.day == 10,
        ),
        isFalse,
      );

      controller.weekStart.value = DateTime(2026, 8, 17);
      await controller.refresh();
      expect(
        controller.items.value.any(
          (i) => i.programDayId == ids[0] && i.scheduledDate.day == 17,
        ),
        isTrue,
      );
    });

    test('перенос скрывает только источник, а не весь день', () async {
      // Два дня программы на вторник: один уходит в перенос, второй остаётся.
      final program = await programRepo.create(
        Program(
          name: 'Два вторника',
          daysCount: 2,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isActive: true,
          activatedAt: DateTime(2024, 1, 1),
        ),
        [
          ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: DateTime.tuesday),
          ProgramDay(programId: 0, dayIndex: 1, dayOfWeek: DateTime.tuesday),
        ],
      );
      final days = await programRepo.getDays(program.id!);
      controller.weekStart.value = DateTime(2026, 8, 10);
      await controller.refresh();

      final tuesdayItems = controller.items.value
          .where((i) => i.scheduledDate.day == 11)
          .toList();
      expect(tuesdayItems, hasLength(2));

      await controller.markRescheduled(tuesdayItems.first);
      final after = controller.items.value
          .where((i) => i.scheduledDate.day == 11)
          .toList();
      expect(after, hasLength(1));
      expect(after.single.programDayId, days.last.id);
    });

    test('маркер переноса не трогает пропуски', () async {
      final ids = await createTwoDayProgram();
      controller.weekStart.value = DateTime(2026, 8, 10);
      await controller.refresh();

      final monday = controller.items.value.firstWhere(
        (i) => i.programDayId == ids[0] && i.scheduledDate.day == 10,
      );
      await controller.markSkipped(monday);
      expect(
        controller.items.value
            .firstWhere(
              (i) => i.programDayId == ids[0] && i.scheduledDate.day == 10,
            )
            .status,
        WeekPlanStatus.skipped,
      );

      final tuesday = controller.items.value.firstWhere(
        (i) => i.programDayId == ids[1] && i.scheduledDate.day == 11,
      );
      await controller.markRescheduled(tuesday);
      expect(
        controller.items.value.any(
          (i) => i.programDayId == ids[0] && i.scheduledDate.day == 10,
        ),
        isTrue,
      );
    });
  });

  test('загрузка плана чистит записи прошлых недель (47.4)', () async {
    final dayId = await createLinkedDay(DateTime.wednesday);
    // Назначение в прошлой неделе — должно исчезнуть при загрузке.
    await scheduleRepo.schedule(dayId, DateTime(2026, 8, 5));
    await WorkoutRepository(db).markSkipped(dayId, DateTime(2026, 8, 3));

    expect(await scheduleRepo.isScheduled(dayId, DateTime(2026, 8, 5)), isTrue);

    controller.weekStart.value = DateTime(2026, 8, 10);
    await controller.refresh();

    expect(
      await scheduleRepo.isScheduled(dayId, DateTime(2026, 8, 5)),
      isFalse,
    );
    expect(await WorkoutRepository(db).getMarks(DateTime(2026, 8, 3)), isEmpty);
    // План текущей недели собирается и содержит тренировку за среду.
    expect(
      controller.items.value.any(
        (i) => i.programDayId == dayId && i.scheduledDate.day == 12,
      ),
      isTrue,
    );
  });
}
