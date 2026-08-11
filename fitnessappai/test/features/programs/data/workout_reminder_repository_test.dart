import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/data/workout_reminder_repository.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository programRepository;
  late WorkoutReminderRepository repository;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    programRepository = ProgramRepository(db);
    repository = WorkoutReminderRepository(db);
    addTearDown(() => db.close());
  });

  Future<ProgramDay> createDay({int? dayOfWeek}) async {
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

  test('saveForDay создаёт, обновляет и возвращает напоминание', () async {
    final day = await createDay(dayOfWeek: 3);

    final created = await repository.saveForDay(
      day.id!,
      hour: 8,
      minute: 30,
      enabled: true,
    );
    expect(created.id, isNotNull);
    expect(created.programDayId, day.id);
    expect(created.hour, 8);
    expect(created.minute, 30);
    expect(created.enabled, isTrue);

    final updated = await repository.saveForDay(
      day.id!,
      hour: 9,
      minute: 15,
      enabled: false,
    );
    expect(updated.id, created.id);
    expect(updated.hour, 9);
    expect(updated.minute, 15);
    expect(updated.enabled, isFalse);
  });

  test(
    'getForDay возвращает null без записи и напоминание после сохранения',
    () async {
      final day = await createDay(dayOfWeek: 1);
      expect(await repository.getForDay(day.id!), isNull);

      await repository.saveForDay(day.id!, hour: 7, minute: 0, enabled: true);
      final reminder = await repository.getForDay(day.id!);
      expect(reminder, isNotNull);
      expect(reminder!.hour, 7);
    },
  );

  test('deleteForDay удаляет напоминание', () async {
    final day = await createDay(dayOfWeek: 5);
    await repository.saveForDay(day.id!, hour: 10, minute: 0, enabled: true);
    expect(await repository.getForDay(day.id!), isNotNull);

    await repository.deleteForDay(day.id!);
    expect(await repository.getForDay(day.id!), isNull);
  });

  test(
    'allScheduled возвращает день недели, название программы и номер дня',
    () async {
      final program = await programRepository.create(
        Program(
          name: 'Беговая',
          daysCount: 2,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        [
          ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: 2),
          ProgramDay(programId: 0, dayIndex: 1, dayOfWeek: 4),
        ],
      );
      final days = await programRepository.getDays(program.id!);
      await repository.saveForDay(
        days[0].id!,
        hour: 8,
        minute: 0,
        enabled: true,
      );
      await repository.saveForDay(
        days[1].id!,
        hour: 18,
        minute: 30,
        enabled: false,
      );

      final scheduled = await repository.allScheduled();
      expect(scheduled, hasLength(2));
      expect(scheduled[0].programName, 'Беговая');
      expect(scheduled[0].dayOfWeek, 2);
      expect(scheduled[0].dayNumber, 1);
      expect(scheduled[1].dayOfWeek, 4);
      expect(scheduled[1].dayNumber, 2);
    },
  );

  test('удаление дня удаляет напоминание (FK cascade)', () async {
    final day = await createDay(dayOfWeek: 6);
    await repository.saveForDay(day.id!, hour: 9, minute: 0, enabled: true);
    expect(await repository.allScheduled(), hasLength(1));

    await programRepository.removeDay(day.id!);
    expect(await repository.allScheduled(), isEmpty);
  });
}
