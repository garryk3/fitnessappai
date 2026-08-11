import 'package:fitnessappai/features/llm/domain/exercise_suggestion.dart';

/// Абстракция генерации контента упражнения (архитектура для задачи 6.x).
///
/// Реализация на локальной LLM появится позже; в MVP используется
/// заглушка [UnsupportedGenerator].
abstract class ExerciseContentGenerator {
  /// Генерирует контент упражнения по подсказке-названию.
  Future<ExerciseSuggestion> generate(String nameHint);
}
