import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';

void main() {
  final now = DateTime(2026, 8, 9);

  test('Program.copyWith и равенство', () {
    final p = Program(
      id: 1,
      name: 'База',
      description: 'Стартовая программа',
      daysCount: 3,
      createdAt: now,
      updatedAt: now,
    );
    expect(p.copyWith(name: 'Продвинутая').name, 'Продвинутая');
    expect(p.copyWith(clearId: true).id, isNull);
    expect(
      p,
      Program(
        id: 1,
        name: 'База',
        description: 'Стартовая программа',
        daysCount: 3,
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(p, isNot(p.copyWith(daysCount: 4)));
  });

  test('ProgramDay.copyWith и равенство', () {
    final day = const ProgramDay(
      id: 10,
      programId: 1,
      dayIndex: 0,
      dayOfWeek: 1,
    );
    expect(day.copyWith(dayIndex: 1).dayIndex, 1);
    expect(day.copyWith(clearDayOfWeek: true).dayOfWeek, isNull);
    expect(day.copyWith(clearId: true).id, isNull);
    expect(
      day,
      const ProgramDay(id: 10, programId: 1, dayIndex: 0, dayOfWeek: 1),
    );
    expect(day, isNot(day.copyWith(dayOfWeek: 2)));
  });

  test('ProgramDayExercise.copyWith и равенство', () {
    const e = ProgramDayExercise(
      id: 100,
      dayId: 10,
      exerciseId: 5,
      orderIndex: 0,
      sets: 3,
      reps: 8,
      weightKg: 16,
      restSeconds: 60,
    );
    expect(e.copyWith(sets: 4).sets, 4);
    expect(e.copyWith(isAlternative: true).isAlternative, isTrue);
    expect(e.copyWith(clearExerciseId: true).exerciseId, isNull);
    expect(e.copyWith(clearId: true).id, isNull);
    expect(
      e,
      const ProgramDayExercise(
        id: 100,
        dayId: 10,
        exerciseId: 5,
        orderIndex: 0,
        sets: 3,
        reps: 8,
        weightKg: 16,
        restSeconds: 60,
      ),
    );
    expect(e, isNot(e.copyWith(restSeconds: 30)));
  });
}
