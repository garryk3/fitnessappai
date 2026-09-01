import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository programRepo;
  late WorkoutRepository workoutRepo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    programRepo = ProgramRepository(db);
    workoutRepo = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<ProgramDay> createDay(int dayOfWeek) async {
    final created = await programRepo.create(
      Program(
        name: 'База',
        daysCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isActive: true,
        activatedAt: DateTime(2024, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: dayOfWeek)],
    );
    return (await programRepo.getDays(created.id!)).first;
  }

  WeekPlanItem itemFor(int programDayId, DateTime weekStart) => WeekPlanItem(
    programDayId: programDayId,
    dayIndex: 0,
    programName: 'База',
    dayOfWeek: 1,
    scheduledDate: weekStart,
    status: WeekPlanStatus.pending,
  );

  Future<Map<int, int>> createMultiDayProgram({
    DateTime? activatedAt,
    DateTime? deactivatedAt,
  }) async {
    final created = await programRepo.create(
      Program(
        name: 'Недельная',
        daysCount: 7,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isActive: true,
        activatedAt: activatedAt ?? DateTime(2024, 1, 1),
        deactivatedAt: deactivatedAt,
      ),
      [
        for (var d = 1; d <= 7; d++)
          ProgramDay(programId: 0, dayIndex: d - 1, dayOfWeek: d),
      ],
    );
    final days = await programRepo.getDays(created.id!);
    return {for (final day in days) day.dayOfWeek!: day.id!};
  }

  test(
    'dayExists: false после удаления программы, true для живого дня',
    () async {
      final deletedDay = await createDay(1);
      final aliveDay = await createDay(2);
      await programRepo.delete(deletedDay.programId);

      final controller = WeekPlanController(
        programRepository: programRepo,
        workoutRepository: workoutRepo,
      );
      await controller.refresh();

      expect(await controller.dayExists(deletedDay.id!), isFalse);
      expect(await controller.dayExists(aliveDay.id!), isTrue);

      controller.dispose();
    },
  );

  test('markSkipped по удалённому дню не падает и чистит план', () async {
    final day = await createDay(1);
    await programRepo.delete(day.programId);

    final controller = WeekPlanController(
      programRepository: programRepo,
      workoutRepository: workoutRepo,
    );
    await controller.refresh();
    final weekStart = controller.weekStart.value;

    await controller.markSkipped(itemFor(day.id!, weekStart));

    expect(controller.items.value, isEmpty);
    expect(await workoutRepo.getSkips(weekStart), isEmpty);

    controller.dispose();
  });

  test('clearSkip по удалённому дню не падает и чистит план', () async {
    final day = await createDay(1);
    await programRepo.delete(day.programId);

    final controller = WeekPlanController(
      programRepository: programRepo,
      workoutRepository: workoutRepo,
    );
    await controller.refresh();
    final weekStart = controller.weekStart.value;

    await controller.clearSkip(itemFor(day.id!, weekStart));

    expect(controller.items.value, isEmpty);
    expect(await workoutRepo.getSkips(weekStart), isEmpty);

    controller.dispose();
  });

  test('markSkipped по живому дню создаёт отметку', () async {
    final day = await createDay(1);

    final controller = WeekPlanController(
      programRepository: programRepo,
      workoutRepository: workoutRepo,
    );
    await controller.refresh();
    final weekStart = controller.weekStart.value;

    await controller.markSkipped(itemFor(day.id!, weekStart));

    final skips = await workoutRepo.getSkips(weekStart);
    expect(skips.map((mark) => mark.programDayId), [day.id]);
    expect(controller.items.value.single.status, WeekPlanStatus.skipped);

    controller.dispose();
  });

  test(
    'nextPending: возвращает ближайший pending день, начиная с сегодня',
    () async {
      final today = DateTime(2026, 8, 12);
      final past = await createDay(2);
      final upcoming = await createDay(4);

      final controller = WeekPlanController(
        programRepository: programRepo,
        workoutRepository: workoutRepo,
        clock: () => today,
      );
      await controller.refresh();

      final next = controller.nextPending;
      expect(next, isNotNull);
      expect(next!.programDayId, upcoming.id);
      expect(next.scheduledDate.isBefore(today), isFalse);

      await controller.markSkipped(
        itemFor(upcoming.id!, controller.weekStart.value),
      );
      await controller.refresh();

      expect(controller.nextPending!.programDayId, past.id);

      controller.dispose();
    },
  );

  test(
    'день в текущей неделе — pending, в прошлой (>3 дней) — pastSkipped',
    () async {
      final today = DateTime(2026, 8, 10);
      await createDay(1);

      final controller = WeekPlanController(
        programRepository: programRepo,
        workoutRepository: workoutRepo,
        clock: () => today,
      );
      await controller.refresh();

      // Текущая неделя: день на Пн совпадает с сегодня — pending.
      expect(controller.items.value.single.status, WeekPlanStatus.pending);

      // Прошлая неделя: тот же день стоит 7 дней назад — автоматически пропущен.
      controller.shiftWeek(-1);
      await controller.refresh();
      expect(controller.items.value.single.status, WeekPlanStatus.pastSkipped);

      controller.dispose();
    },
  );

  test(
    'день в пределах 3 дней остаётся pending, старше 3 — pastSkipped',
    () async {
      final today = DateTime(2026, 8, 12);
      // Пт (08-14) — в будущем, Пн (08-10) — 2 дня назад: оба в окне переноса.
      final monday = await createDay(1);
      final friday = await createDay(5);

      final controller = WeekPlanController(
        programRepository: programRepo,
        workoutRepository: workoutRepo,
        clock: () => today,
      );
      await controller.refresh();

      final statuses = {
        for (final item in controller.items.value)
          item.programDayId: item.status,
      };
      expect(statuses[monday.id], WeekPlanStatus.pending);
      expect(statuses[friday.id], WeekPlanStatus.pending);

      // Прошлая неделя (>= 7 дней назад) — за окном 3 дней: pastSkipped.
      controller.shiftWeek(-1);
      await controller.refresh();
      final pastStatuses = {
        for (final item in controller.items.value)
          item.programDayId: item.status,
      };
      expect(pastStatuses[monday.id], WeekPlanStatus.pastSkipped);
      expect(pastStatuses[friday.id], WeekPlanStatus.pastSkipped);

      controller.dispose();
    },
  );

  test('nextPending не учитывает pastSkipped дни', () async {
    final today = DateTime(2026, 8, 12);
    await createDay(1);
    await createDay(5);

    final controller = WeekPlanController(
      programRepository: programRepo,
      workoutRepository: workoutRepo,
      clock: () => today,
    );
    await controller.refresh();

    // Текущая неделя: все дни в окне — nextPending возвращает ближайший pending.
    expect(controller.nextPending, isNotNull);
    for (final item in controller.items.value) {
      expect(item.status, isNot(WeekPlanStatus.pastSkipped));
    }

    // Прошлая неделя: все дни pastSkipped → nextPending отсутствует.
    controller.shiftWeek(-1);
    await controller.refresh();
    expect(controller.nextPending, isNull);
    for (final item in controller.items.value) {
      expect(item.status, WeekPlanStatus.pastSkipped);
    }

    controller.dispose();
  });

  test('дни до даты активации программы не показываются в плане', () async {
    final today = DateTime(2026, 8, 10);
    // Активация в Ср (08-12): Пн и Вт до неё должны быть скрыты.
    final days = await createMultiDayProgram(
      activatedAt: DateTime(2026, 8, 12),
    );

    final controller = WeekPlanController(
      programRepository: programRepo,
      workoutRepository: workoutRepo,
      clock: () => today,
    );
    await controller.refresh();

    final visible = controller.items.value.map((e) => e.programDayId).toSet();
    expect(visible, isNot(contains(days[1])));
    expect(visible, isNot(contains(days[2])));
    expect(visible, contains(days[3]));
    expect(visible, contains(days[7]));

    controller.dispose();
  });

  test(
    'дни после даты деактивации программы не показываются в плане',
    () async {
      final today = DateTime(2026, 8, 10);
      // Деактивация в Чт (08-13): Чт и позже должны быть скрыты.
      final days = await createMultiDayProgram(
        deactivatedAt: DateTime(2026, 8, 13),
      );

      final controller = WeekPlanController(
        programRepository: programRepo,
        workoutRepository: workoutRepo,
        clock: () => today,
      );
      await controller.refresh();

      final visible = controller.items.value.map((e) => e.programDayId).toSet();
      expect(visible, contains(days[1]));
      expect(visible, contains(days[3]));
      expect(visible, isNot(contains(days[4])));
      expect(visible, isNot(contains(days[7])));

      controller.dispose();
    },
  );

  test('режим «Месяц» загружает все дни месяца', () async {
    final today = DateTime(2026, 8, 10);
    await createDay(1);

    final controller = WeekPlanController(
      programRepository: programRepo,
      workoutRepository: workoutRepo,
      clock: () => today,
    );
    await controller.setViewMode(PlanViewMode.month);

    expect(controller.viewMode.value, PlanViewMode.month);
    // Август 2026: понедельники 3, 10, 17, 24, 31.
    final mondays = controller.items.value
        .map((e) => e.scheduledDate.day)
        .toSet();
    expect(mondays, {3, 10, 17, 24, 31});

    controller.dispose();
  });

  test('смена месяца переключает загруженный диапазон', () async {
    final today = DateTime(2026, 8, 10);
    await createDay(1);

    final controller = WeekPlanController(
      programRepository: programRepo,
      workoutRepository: workoutRepo,
      clock: () => today,
    );
    await controller.setViewMode(PlanViewMode.month);
    controller.shiftMonth(1);
    await controller.refresh();

    // Сентябрь 2026: понедельники 7, 14, 21, 28.
    final mondays = controller.items.value
        .map((e) => e.scheduledDate.day)
        .toSet();
    expect(mondays, {7, 14, 21, 28});

    controller.dispose();
  });

  test('возврат в режим «Неделя» снова грузит неделю', () async {
    final today = DateTime(2026, 8, 10);
    await createDay(1);

    final controller = WeekPlanController(
      programRepository: programRepo,
      workoutRepository: workoutRepo,
      clock: () => today,
    );
    await controller.setViewMode(PlanViewMode.month);
    await controller.setViewMode(PlanViewMode.week);

    expect(controller.viewMode.value, PlanViewMode.week);
    expect(controller.items.value, hasLength(1));
    // Единственный день — Пн текущей недели (08-10).
    expect(controller.items.value.single.scheduledDate, DateTime(2026, 8, 10));

    controller.dispose();
  });

  test('неактивная программа не попадает в план', () async {
    final today = DateTime(2026, 8, 10);
    // Активная программа.
    await createDay(1);
    // Неактивная программа: создаём без isActive.
    await programRepo.create(
      Program(
        name: 'Неактивная',
        daysCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: 3)],
    );

    final controller = WeekPlanController(
      programRepository: programRepo,
      workoutRepository: workoutRepo,
      clock: () => today,
    );
    await controller.refresh();

    expect(controller.items.value, hasLength(1));
    expect(controller.items.value.single.programName, 'База');

    controller.dispose();
  });
}
