import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_cleanup.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

void main() {
  late AppDatabase db;
  late PlanScheduleRepository scheduleRepo;
  late WorkoutRepository workoutRepo;
  late PlanScheduleCleaner cleaner;
  late int dayId;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    scheduleRepo = PlanScheduleRepository(db);
    workoutRepo = WorkoutRepository(db);
    cleaner = PlanScheduleCleaner(
      workoutRepository: workoutRepo,
      planScheduleRepository: scheduleRepo,
    );
    final programRepo = ProgramRepository(db);
    final program = await programRepo.create(
      Program(
        name: 'Тестовая',
        daysCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isActive: true,
        activatedAt: DateTime(2024, 1, 1),
      ),
      [const ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: 1)],
    );
    final days = await programRepo.getDays(program.id!);
    dayId = days.first.id!;
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'cleanupOldSchedule удаляет назначения и отметки прошлых недель',
    () async {
      await scheduleRepo.schedule(dayId, DateTime(2026, 8, 3));
      await scheduleRepo.schedule(dayId, DateTime(2026, 8, 12));
      await workoutRepo.markSkipped(dayId, DateTime(2026, 8, 3));
      await workoutRepo.markSkipped(dayId, DateTime(2026, 8, 10));

      // 13.08.2026 — четверг, понедельник текущей недели 10.08.
      final removed = await cleaner.cleanupOldSchedule(DateTime(2026, 8, 13));

      expect(removed, 2);
      expect(
        await scheduleRepo.isScheduled(dayId, DateTime(2026, 8, 3)),
        isFalse,
      );
      expect(
        await scheduleRepo.isScheduled(dayId, DateTime(2026, 8, 12)),
        isTrue,
      );
      expect(await workoutRepo.getMarks(DateTime(2026, 8, 3)), isEmpty);
      expect(await workoutRepo.getMarks(DateTime(2026, 8, 10)), hasLength(1));
    },
  );

  test(
    'cleanupOldSchedule без репозитория расписания чистит только отметки',
    () async {
      final marksOnly = PlanScheduleCleaner(workoutRepository: workoutRepo);
      await workoutRepo.markSkipped(dayId, DateTime(2026, 8, 3));

      expect(await marksOnly.cleanupOldSchedule(DateTime(2026, 8, 13)), 1);
      expect(await workoutRepo.getMarks(DateTime(2026, 8, 3)), isEmpty);
    },
  );

  test('cleanupOldSchedule ничего не удаляет на текущей неделе', () async {
    await scheduleRepo.schedule(dayId, DateTime(2026, 8, 10));
    await workoutRepo.markSkipped(dayId, DateTime(2026, 8, 10));

    expect(await cleaner.cleanupOldSchedule(DateTime(2026, 8, 10)), 0);
    expect(
      await scheduleRepo.isScheduled(dayId, DateTime(2026, 8, 10)),
      isTrue,
    );
    expect(await workoutRepo.getMarks(DateTime(2026, 8, 10)), hasLength(1));
  });

  test('mondayOf даёт понедельник недели', () {
    expect(mondayOf(DateTime(2026, 8, 13)), DateTime(2026, 8, 10));
    expect(mondayOf(DateTime(2026, 8, 10)), DateTime(2026, 8, 10));
    expect(mondayOf(DateTime(2026, 8, 16)), DateTime(2026, 8, 10));
  });
}
