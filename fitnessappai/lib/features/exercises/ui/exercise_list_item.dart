import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';

/// Элемент списка упражнений: карточка + данные для бейджей.
class ExerciseListItem {
  const ExerciseListItem({
    required this.exercise,
    required this.muscles,
    required this.hasContraindications,
  });

  final Exercise exercise;
  final List<MuscleGroup> muscles;
  final bool hasContraindications;
}
