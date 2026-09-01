import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Снимок состояния тренировки для восстановления после убийства процесса ОС.
///
/// Содержит только serializers данные, необходимые для перезапуска сессии:
/// ID дня программы, текущий индекс упражнения, завершённые подходы, фазу
/// (включая отдых и удержание планки) и т.д.
class WorkoutCheckpoint {
  const WorkoutCheckpoint({
    required this.programDayId,
    required this.exerciseIndex,
    required this.currentSet,
    required this.completedSets,
    required this.resultsJson,
    required this.startedAt,
    this.programId,
    required this.programName,
    required this.dayIndex,
    this.currentSide,
    this.phase = 'exercise',
    this.restEndsAt,
    this.restBetweenExercises = false,
    this.sideRest = false,
    this.holdElapsedSeconds = 0,
    this.holdTargetSeconds,
    this.holdRunning = false,
  });

  factory WorkoutCheckpoint.fromJson(Map<String, dynamic> json) =>
      WorkoutCheckpoint(
        programDayId: json['programDayId'] as int,
        exerciseIndex: json['exerciseIndex'] as int,
        currentSet: json['currentSet'] as int,
        completedSets: json['completedSets'] as int,
        resultsJson: json['resultsJson'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        programId: json['programId'] as int?,
        programName: json['programName'] as String,
        dayIndex: json['dayIndex'] as int,
        currentSide: json['currentSide'] as String?,
        phase: json['phase'] as String? ?? 'exercise',
        restEndsAt: json['restEndsAt'] == null
            ? null
            : DateTime.parse(json['restEndsAt'] as String),
        restBetweenExercises: json['restBetweenExercises'] as bool? ?? false,
        sideRest: json['sideRest'] as bool? ?? false,
        holdElapsedSeconds: json['holdElapsedSeconds'] as int? ?? 0,
        holdTargetSeconds: json['holdTargetSeconds'] as int?,
        holdRunning: json['holdRunning'] as bool? ?? false,
      );

  final int programDayId;
  final int exerciseIndex;
  final int currentSet;
  final int completedSets;
  final String resultsJson;
  final DateTime startedAt;
  final int? programId;
  final String programName;
  final int dayIndex;
  final String? currentSide;

  /// Название фазы (`WorkoutPhase.name`) на момент снимка.
  final String phase;

  /// Время окончания отдыха по wall-clock (null — отдых не идёт).
  final DateTime? restEndsAt;

  /// Идёт ли пауза отдыха между упражнениями.
  final bool restBetweenExercises;

  /// Идёт ли отдых между сторонами упражнения «по сторонам».
  final bool sideRest;

  final int holdElapsedSeconds;
  final int? holdTargetSeconds;
  final bool holdRunning;

  Map<String, dynamic> toJson() => {
    'programDayId': programDayId,
    'exerciseIndex': exerciseIndex,
    'currentSet': currentSet,
    'completedSets': completedSets,
    'resultsJson': resultsJson,
    'startedAt': startedAt.toIso8601String(),
    'programId': programId,
    'programName': programName,
    'dayIndex': dayIndex,
    'currentSide': currentSide,
    'phase': phase,
    'restEndsAt': restEndsAt?.toIso8601String(),
    'restBetweenExercises': restBetweenExercises,
    'sideRest': sideRest,
    'holdElapsedSeconds': holdElapsedSeconds,
    'holdTargetSeconds': holdTargetSeconds,
    'holdRunning': holdRunning,
  };

  static const _fileName = 'workout_checkpoint.json';

  /// Сохраняет чекпоинт на диск.
  Future<void> save() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    await file.writeAsString(jsonEncode(toJson()));
  }

  /// Статическая версия [save] для использования как callback.
  static Future<void> saveStatic(WorkoutCheckpoint checkpoint) async {
    await checkpoint.save();
  }

  /// Загружает чекпоинт с диска. Возвращает `null`, если файла нет.
  static Future<WorkoutCheckpoint?> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (!file.existsSync()) {
        return null;
      }
      final content = await file.readAsString();
      return WorkoutCheckpoint.fromJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Удаляет файл чекпоинта.
  static Future<void> clear() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (_) {
      // ignore
    }
  }
}
