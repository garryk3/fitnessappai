import 'package:fitnessappai/core/domain/models/exercise_type.dart';

/// Стартовые метрики позиции дня программы по типу упражнения (задача 67.2).
///
/// Убирает ручной ввод всех обязательных полей при добавлении упражнения:
/// экран параметров открывается с осмысленными значениями, которые можно
/// изменить. Вес не задаётся — его нельзя угадать по типу упражнения.
class ProgramDayExerciseDefaults {
  const ProgramDayExerciseDefaults({
    this.sets,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
    this.restSeconds,
  });

  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? restSeconds;

  /// Пустые значения — тип упражнения неизвестен, форма оставляет поля пустыми.
  static const ProgramDayExerciseDefaults empty = ProgramDayExerciseDefaults();

  /// Дефолты для [type]:
  /// - силовые и свои вес — 3 × 10, отдых 60 с;
  /// - планка — 1 подход 30 с (цель удержания), отдых 30 с;
  /// - дистанция — 1 км за 10 мин, отдых 30 с.
  static ProgramDayExerciseDefaults forType(ExerciseType type) =>
      switch (type) {
        ExerciseType.strength ||
        ExerciseType.bodyweight => const ProgramDayExerciseDefaults(
          sets: 3,
          reps: 10,
          restSeconds: 60,
        ),
        ExerciseType.plank => const ProgramDayExerciseDefaults(
          sets: 1,
          durationSeconds: 30,
          restSeconds: 30,
        ),
        ExerciseType.distance => const ProgramDayExerciseDefaults(
          sets: 1,
          durationSeconds: 600,
          distanceMeters: 1000,
          restSeconds: 30,
        ),
      };
}
