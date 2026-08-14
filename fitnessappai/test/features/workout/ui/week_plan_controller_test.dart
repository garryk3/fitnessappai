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
      final today = DateTime.now();
      final weekday = today.weekday;
      final past = await createDay(weekday >= 2 ? weekday - 1 : 7);
      final upcoming = await createDay(weekday >= 7 ? 1 : weekday + 1);

      final controller = WeekPlanController(
        programRepository: programRepo,
        workoutRepository: workoutRepo,
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
}
