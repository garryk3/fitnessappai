import 'package:fitnessappai/core/domain/models/exercise_type.dart';

/// Результат генерации контента упражнения.
///
/// DTO по контракту `docs/llm_contract.md`; `muscles` и `contraindications`
/// содержат ключи справочников (`quads`, `knees` и т. п.).
class ExerciseSuggestion {
  const ExerciseSuggestion({
    required this.name,
    required this.description,
    required this.type,
    required this.contraindications,
    required this.muscles,
    required this.instructions,
    required this.commonMistakes,
  });

  final String name;
  final String description;
  final ExerciseType type;
  final List<String> contraindications;
  final List<String> muscles;
  final String instructions;
  final List<String> commonMistakes;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExerciseSuggestion &&
            other.name == name &&
            other.description == description &&
            other.type == type &&
            _listEquals(other.contraindications, contraindications) &&
            _listEquals(other.muscles, muscles) &&
            other.instructions == instructions &&
            _listEquals(other.commonMistakes, commonMistakes);
  }

  @override
  int get hashCode => Object.hash(
    name,
    description,
    type,
    Object.hashAll(contraindications),
    Object.hashAll(muscles),
    instructions,
    Object.hashAll(commonMistakes),
  );

  @override
  String toString() =>
      'ExerciseSuggestion(name: $name, type: $type, muscles: $muscles)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
