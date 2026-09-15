import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
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
}
