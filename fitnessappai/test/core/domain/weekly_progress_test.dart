import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/weekly_progress.dart';

void main() {
  ProgramDay day(int id, {int? dayOfWeek, int programId = 1}) => ProgramDay(
    id: id,
    programId: programId,
    dayIndex: id - 1,
    dayOfWeek: dayOfWeek,
  );

  WorkoutSession session({
    int? programId,
    int? programDayId,
    DateTime? performedDate,
  }) => WorkoutSession(
    programId: programId,
    programName: 'База',
    programDayId: programDayId,
    dayIndex: 0,
    performedDate: performedDate ?? DateTime(2026, 10, 12),
    startedAt: DateTime(2026, 10, 12, 18),
    endedAt: DateTime(2026, 10, 12, 18, 40),
  );

  group('weeklyProgressPercent (перенос из home_controller, 54.4)', () {
    test('1 из 3 → 33', () {
      expect(weeklyProgressPercent(performedDays: 1, assignedDays: 3), 33);
    });

    test('2 из 3 → 67', () {
      expect(weeklyProgressPercent(performedDays: 2, assignedDays: 3), 67);
    });

    test('пустой знаменатель → null', () {
      expect(weeklyProgressPercent(performedDays: 0, assignedDays: 0), isNull);
    });

    test('знаменатель может превышаться (непривязанные дни, 48.2)', () {
      expect(weeklyProgressPercent(performedDays: 4, assignedDays: 3), 133);
    });
  });

  group('weeklyProgramProgress', () {
    test('без дней → null', () {
      expect(
        weeklyProgramProgress(days: const [], sessions: const [], programId: 1),
        isNull,
      );
    });

    test('привязанные дни: день со сессией по programDayId засчитан', () {
      final days = [
        day(1, dayOfWeek: 1),
        day(2, dayOfWeek: 3),
        day(3, dayOfWeek: 5),
      ];
      final result = weeklyProgramProgress(
        days: days,
        sessions: [session(programId: 1, programDayId: 1)],
        programId: 1,
      );
      expect(result, (performed: 1, assigned: 3));
    });

    test('привязанные дни: сессия чужого дня не считается', () {
      final days = [day(1, dayOfWeek: 1), day(2, dayOfWeek: 3)];
      final result = weeklyProgramProgress(
        days: days,
        sessions: [session(programId: 1, programDayId: 99)],
        programId: 1,
      );
      expect(result, (performed: 0, assigned: 2));
    });

    test('день без id не может иметь сессий', () {
      final days = [const ProgramDay(programId: 1, dayIndex: 0, dayOfWeek: 1)];
      final result = weeklyProgramProgress(
        days: days,
        sessions: [session(programId: 1, programDayId: null)],
        programId: 1,
      );
      expect(result, (performed: 0, assigned: 1));
    });

    test('непривязанные дни: числитель — сессии по programId', () {
      final days = [
        day(1),
        day(2),
        day(3),
      ];
      final result = weeklyProgramProgress(
        days: days,
        sessions: [
          session(programId: 1),
          session(programId: 1),
          session(programId: 2),
          session(programId: null),
        ],
        programId: 1,
      );
      expect(result, (performed: 2, assigned: 3));
    });

    test('смешанные дни (есть с dayOfWeek == null) — ветка по programId', () {
      final days = [day(1, dayOfWeek: 1), day(2)];
      final result = weeklyProgramProgress(
        days: days,
        sessions: [session(programId: 1, programDayId: 99)],
        programId: 1,
      );
      expect(result, (performed: 1, assigned: 2));
    });

    test('можно выполнить больше, чем дней (48.2)', () {
      final days = [day(1), day(2), day(3)];
      final result = weeklyProgramProgress(
        days: days,
        sessions: [
          session(programId: 1),
          session(programId: 1),
          session(programId: 1),
          session(programId: 1),
        ],
        programId: 1,
      );
      expect(result, (performed: 4, assigned: 3));
      expect(
        weeklyProgressPercent(
          performedDays: result!.performed,
          assignedDays: result.assigned,
        ),
        133,
      );
    });
  });
}
