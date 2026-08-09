import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/validators/program_validator.dart';

void main() {
  final validator = ProgramValidator();
  final now = DateTime(2026, 8, 9);

  ProgramDayExercise exercise({int dayId = 1, bool isAlternative = false}) {
    return ProgramDayExercise(
      dayId: dayId,
      exerciseId: 5,
      orderIndex: 0,
      sets: 3,
      reps: 8,
      isAlternative: isAlternative,
    );
  }

  test('валидная программа (3 дня, у каждого основное упражнение)', () {
    final program = Program(
      name: 'База',
      daysCount: 3,
      createdAt: now,
      updatedAt: now,
    );
    final days = [
      for (var i = 0; i < 3; i++) ProgramDay(programId: 1, dayIndex: i),
    ];
    final result = validator.validate(
      program: program,
      days: days,
      exercisesByDayIndex: {
        for (final d in days) d.dayIndex: [exercise(dayId: d.id ?? 0)],
      },
    );
    expect(result.isValid, isTrue);
  });

  test('день без основного упражнения невалиден', () {
    final program = Program(
      name: 'База',
      daysCount: 2,
      createdAt: now,
      updatedAt: now,
    );
    final days = [
      ProgramDay(programId: 1, dayIndex: 0),
      ProgramDay(programId: 1, dayIndex: 1),
    ];
    final result = validator.validate(
      program: program,
      days: days,
      exercisesByDayIndex: {
        0: [exercise(dayId: 1)],
        1: <ProgramDayExercise>[],
      },
    );
    expect(result.isValid, isFalse);
    expect(result.errors, anyElement(contains('основное упражнение')));
  });

  test('день только с альтернативным упражнением невалиден', () {
    final program = Program(
      name: 'База',
      daysCount: 1,
      createdAt: now,
      updatedAt: now,
    );
    final result = validator.validate(
      program: program,
      days: [ProgramDay(programId: 1, dayIndex: 0)],
      exercisesByDayIndex: {
        0: [exercise(dayId: 1, isAlternative: true)],
      },
    );
    expect(result.isValid, isFalse);
  });

  test('количество дней вне 1–7 отклоняется', () {
    for (final count in [0, 8]) {
      final program = Program(
        name: 'База',
        daysCount: count,
        createdAt: now,
        updatedAt: now,
      );
      final days = [
        for (var i = 0; i < count; i++) ProgramDay(programId: 1, dayIndex: i),
      ];
      final result = validator.validate(
        program: program,
        days: days,
        exercisesByDayIndex: {},
      );
      expect(result.isValid, isFalse, reason: 'дней: $count');
    }
  });

  test('неуникальные dayIndex невалидны', () {
    final program = Program(
      name: 'База',
      daysCount: 2,
      createdAt: now,
      updatedAt: now,
    );
    final days = [
      ProgramDay(programId: 1, dayIndex: 0),
      ProgramDay(programId: 1, dayIndex: 0),
    ];
    final result = validator.validate(
      program: program,
      days: days,
      exercisesByDayIndex: {
        0: [exercise(dayId: 1)],
      },
    );
    expect(result.isValid, isFalse);
    expect(result.errors, anyElement(contains('уникальными')));
  });

  test('daysCount не совпадает с днями — невалидно', () {
    final program = Program(
      name: 'База',
      daysCount: 4,
      createdAt: now,
      updatedAt: now,
    );
    final days = [
      for (var i = 0; i < 3; i++) ProgramDay(programId: 1, dayIndex: i),
    ];
    final result = validator.validate(
      program: program,
      days: days,
      exercisesByDayIndex: {},
    );
    expect(result.isValid, isFalse);
    expect(result.errors, anyElement(contains('daysCount')));
  });

  test('пустое название программы невалидно', () {
    final program = Program(
      name: '  ',
      daysCount: 1,
      createdAt: now,
      updatedAt: now,
    );
    final result = validator.validate(
      program: program,
      days: [ProgramDay(programId: 1, dayIndex: 0)],
      exercisesByDayIndex: {
        0: [exercise(dayId: 1)],
      },
    );
    expect(result.isValid, isFalse);
  });
}
