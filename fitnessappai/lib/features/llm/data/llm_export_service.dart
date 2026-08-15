import 'dart:convert';

import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';

/// Экспорт программ и истории тренировок в JSON для LLM.
///
/// Результат — компактное, самодостаточное представление данных без ссылок
/// на внутренние id БД: названия и метрики дублируются в каждом упражнении.
class LlmExportService {
  LlmExportService({
    required this.programRepository,
    required this.exerciseRepository,
    required this.workoutRepository,
  });

  final ProgramRepository programRepository;
  final ExerciseRepository exerciseRepository;
  final WorkoutRepository workoutRepository;

  /// JSON-представление программы по [id] или `null`, если программа не найдена.
  Future<String?> programToJson(int id) async {
    final detail = await programRepository.getProgram(id);
    if (detail == null) {
      return null;
    }
    final names = await _exerciseNames(detail);
    final json = <String, Object?>{
      'type': 'program',
      'id': detail.program.id,
      'name': detail.program.name,
      'description': detail.program.description,
      'daysCount': detail.program.daysCount,
      'days': [for (final day in detail.days) _dayJson(day.day, day, names)],
    };
    return jsonEncode(json);
  }

  /// JSON-представление всей истории тренировок.
  Future<String> historyToJson() async {
    final sessions = await workoutRepository.getAllSessions();
    final json = <String, Object?>{
      'type': 'history',
      'sessions': [for (final session in sessions) await _sessionJson(session)],
    };
    return jsonEncode(json);
  }

  Future<Map<int, String?>> _exerciseNames(ProgramDetail detail) async {
    final ids = <int>{
      for (final day in detail.days) ...[
        for (final e in day.mainExercises) ..._idsOf(e),
        for (final e in day.alternativeExercises) ..._idsOf(e),
      ],
    };
    final names = <int, String?>{};
    for (final id in ids) {
      final exercise = await exerciseRepository.getById(id);
      names[id] = exercise?.name;
    }
    return names;
  }

  List<int> _idsOf(ProgramDayExercise e) =>
      e.exerciseId == null ? const [] : [e.exerciseId!];

  Map<String, Object?> _dayJson(
    ProgramDay day,
    ProgramDayDetail detail,
    Map<int, String?> names,
  ) {
    return {
      'dayIndex': day.dayIndex,
      'dayOfWeek': day.dayOfWeek,
      'exercises': [
        for (final e in detail.mainExercises) _exerciseJson(e, names),
        for (final e in detail.alternativeExercises) _exerciseJson(e, names),
      ],
    };
  }

  Map<String, Object?> _exerciseJson(
    ProgramDayExercise e,
    Map<int, String?> names,
  ) {
    return {
      'name': e.exerciseId == null ? null : names[e.exerciseId],
      'exerciseId': e.exerciseId,
      'sets': e.sets,
      'reps': e.reps,
      'weightKg': e.weightKg,
      'durationSeconds': e.durationSeconds,
      'distanceMeters': e.distanceMeters,
      'restSeconds': e.restSeconds,
      'isAlternative': e.isAlternative,
    };
  }

  Future<Map<String, Object?>> _sessionJson(WorkoutSession session) async {
    final detail = await workoutRepository.getSession(session.id!);
    final setsByName = <String, List<WorkoutSetResult>>{};
    for (final result in detail?.results ?? const <WorkoutSetResult>[]) {
      setsByName.putIfAbsent(result.exerciseName, () => []).add(result);
    }
    return {
      'id': session.id,
      'programName': session.programName,
      'dayIndex': session.dayIndex,
      'variant': session.variant.name,
      'performedDate': session.performedDate.toIso8601String(),
      'startedAt': session.startedAt.toIso8601String(),
      'endedAt': session.endedAt.toIso8601String(),
      'exercises': [
        for (final entry in setsByName.entries) _setsJson(entry.value),
      ],
    };
  }

  Map<String, Object?> _setsJson(List<WorkoutSetResult> results) {
    final first = results.first;
    return {
      'name': first.exerciseName,
      'exerciseId': first.exerciseId,
      'type': first.exerciseType.name,
      'sets': [for (final r in results) _setJson(r)],
    };
  }

  Map<String, Object?> _setJson(WorkoutSetResult r) {
    return {
      'setIndex': r.setIndex,
      'reps': r.reps,
      'weightKg': r.weightKg,
      'durationSeconds': r.durationSeconds,
      'distanceMeters': r.distanceMeters,
    };
  }
}
