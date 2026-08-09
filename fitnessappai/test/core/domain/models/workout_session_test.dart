import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';

void main() {
  final start = DateTime(2026, 8, 9, 18, 0);
  final end = DateTime(2026, 8, 9, 18, 40);

  test('WorkoutSession.copyWith и равенство', () {
    final s = WorkoutSession(
      id: 1,
      programId: 2,
      programName: 'База',
      programDayId: 3,
      dayIndex: 0,
      variant: WorkoutVariant.main,
      performedDate: start,
      startedAt: start,
      endedAt: end,
    );
    expect(
      s.copyWith(variant: WorkoutVariant.alternative).variant,
      WorkoutVariant.alternative,
    );
    expect(s.copyWith(clearProgramId: true).programId, isNull);
    expect(
      s,
      WorkoutSession(
        id: 1,
        programId: 2,
        programName: 'База',
        programDayId: 3,
        dayIndex: 0,
        performedDate: start,
        startedAt: start,
        endedAt: end,
      ),
    );
    expect(s, isNot(s.copyWith(status: 'cancelled')));
  });

  test('WorkoutSetResult.copyWith и равенство', () {
    final r = WorkoutSetResult(
      id: 1,
      sessionId: 10,
      exerciseId: 5,
      exerciseName: 'Приседания',
      exerciseType: ExerciseType.strength,
      setIndex: 0,
      reps: 8,
      weightKg: 16,
      completedAt: end,
    );
    expect(r.copyWith(reps: 10).reps, 10);
    expect(r.copyWith(clearExerciseId: true).exerciseId, isNull);
    expect(
      r,
      WorkoutSetResult(
        id: 1,
        sessionId: 10,
        exerciseId: 5,
        exerciseName: 'Приседания',
        exerciseType: ExerciseType.strength,
        setIndex: 0,
        reps: 8,
        weightKg: 16,
        completedAt: end,
      ),
    );
    expect(r, isNot(r.copyWith(weightKg: 24)));
  });
}
