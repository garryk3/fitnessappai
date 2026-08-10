import 'package:fitnessappai/core/domain/models/workout_session.dart';

/// Метаданные сессии для записи результата тренировки.
///
/// Программные поля копируются в [WorkoutSession], чтобы история
/// сохранялась после удаления программы.
class WorkoutSessionContext {
  const WorkoutSessionContext({
    this.programId,
    required this.programName,
    this.programDayId,
    required this.dayIndex,
    this.variant = WorkoutVariant.main,
  });

  final int? programId;
  final String programName;
  final int? programDayId;
  final int dayIndex;
  final WorkoutVariant variant;
}
