import 'package:fitnessappai/features/llm/domain/exercise_content_generator.dart';
import 'package:fitnessappai/features/llm/domain/exercise_suggestion.dart';

/// Заглушка генератора для MVP: генерация контента не подключена.
///
/// Зарегистрирована в ServiceLocator, чтобы UI-слой не зависел от наличия
/// реальной LLM-реализации (задача 6.4).
class UnsupportedGenerator implements ExerciseContentGenerator {
  const UnsupportedGenerator();

  @override
  Future<ExerciseSuggestion> generate(String nameHint) {
    return Future.error(
      UnsupportedError('Генерация контента упражнений не подключена'),
    );
  }
}
