// ignore_for_file: type=lint
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';

WorkoutSession _session({required Duration wall}) {
  final start = DateTime(2026, 10, 31, 10);
  return WorkoutSession(
    programName: 'Тест',
    dayIndex: 0,
    performedDate: start,
    startedAt: start,
    endedAt: start.add(wall),
  );
}

WorkoutSetResult _result(ExerciseType type, {int? durationSeconds}) {
  return WorkoutSetResult(
    sessionId: 1,
    exerciseName: 'Тест',
    exerciseType: type,
    setIndex: 0,
    durationSeconds: durationSeconds,
    completedAt: DateTime(2026, 10, 31, 10),
  );
}

void main() {
  test(
    'дистанция 30 мин, введённая после пробежки вне приложения (wall 1 мин) — 30 мин',
    () {
      final session = _session(wall: const Duration(minutes: 1));
      final duration = workoutDisplayDuration(session, [
        _result(ExerciseType.distance, durationSeconds: 30 * 60),
      ]);

      expect(duration, const Duration(minutes: 30));
    },
  );

  test('силовая сессия — wall-clock как раньше', () {
    final session = _session(wall: const Duration(minutes: 8));
    final duration = workoutDisplayDuration(session, [
      _result(ExerciseType.strength),
      _result(ExerciseType.bodyweight),
    ]);

    expect(duration, const Duration(minutes: 8));
  });

  test('планка 3×60 с при wall 5 мин — wall-clock побеждает (не завышает)', () {
    final session = _session(wall: const Duration(minutes: 5));
    final duration = workoutDisplayDuration(session, [
      _result(ExerciseType.plank, durationSeconds: 60),
      _result(ExerciseType.plank, durationSeconds: 60),
      _result(ExerciseType.plank, durationSeconds: 60),
    ]);

    expect(duration, const Duration(minutes: 5));
  });

  test('интервалы 2×15 мин (дистанция) — суммарные 30 мин', () {
    final session = _session(wall: const Duration(minutes: 2));
    final duration = workoutDisplayDuration(session, [
      _result(ExerciseType.distance, durationSeconds: 15 * 60),
      _result(ExerciseType.distance, durationSeconds: 15 * 60),
    ]);

    expect(duration, const Duration(minutes: 30));
  });
}
