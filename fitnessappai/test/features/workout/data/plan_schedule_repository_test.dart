import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/plan_schedule_repository.dart';

void main() {
  late AppDatabase db;
  late PlanScheduleRepository repo;
  late ProgramRepository programRepo;
  late int dayId;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = PlanScheduleRepository(db);
    programRepo = ProgramRepository(db);
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

  test('schedule + getForRange', () async {
    final date = DateTime(2026, 8, 15);
    await repo.schedule(dayId, date);

    final items = await repo.getForRange(
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 31),
    );
    expect(items, hasLength(1));
    expect(items.first.programDayId, equals(dayId));
    expect(items.first.scheduledDate, equals(date));
  });

  test('schedule is idempotent', () async {
    final date = DateTime(2026, 8, 15);
    await repo.schedule(dayId, date);
    await repo.schedule(dayId, date);

    final items = await repo.getForRange(
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 31),
    );
    expect(items, hasLength(1));
  });

  test('cancel removes assignment', () async {
    final date = DateTime(2026, 8, 15);
    await repo.schedule(dayId, date);
    await repo.cancel(dayId, date);

    final items = await repo.getForRange(
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 31),
    );
    expect(items, isEmpty);
  });

  test('isScheduled', () async {
    final date = DateTime(2026, 8, 15);
    expect(await repo.isScheduled(dayId, date), isFalse);
    await repo.schedule(dayId, date);
    expect(await repo.isScheduled(dayId, date), isTrue);
  });

  test('getForRange filters by date', () async {
    await repo.schedule(dayId, DateTime(2026, 8, 10));
    await repo.schedule(dayId, DateTime(2026, 9, 5));

    final augustItems = await repo.getForRange(
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 31),
    );
    expect(augustItems, hasLength(1));

    final allItems = await repo.getForRange(
      DateTime(2026, 8, 1),
      DateTime(2026, 9, 30),
    );
    expect(allItems, hasLength(2));
  });
}
