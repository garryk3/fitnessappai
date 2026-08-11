import 'dart:convert';

import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/features/llm/domain/exercise_suggestion.dart';
import 'package:fitnessappai/features/llm/domain/malformed_suggestion_exception.dart';

/// Строгий разбор JSON-ответа генерации по контракту `docs/llm_contract.md`.
///
/// В отличие от seed-парсера, любое нарушение контракта (отсутствующее поле,
/// неверный тип, невалидное значение) приводит к [MalformedSuggestionException]
/// с описанием проблемы. Лишние поля игнорируются.
class SuggestionJsonParser {
  const SuggestionJsonParser();

  /// Разбирает декодированный JSON-объект.
  ExerciseSuggestion fromJson(Map<String, dynamic> json) {
    final name = _requiredString(json, 'name');
    if (name.trim().isEmpty) {
      throw const MalformedSuggestionException('"name" не может быть пустым');
    }

    final type = _parseType(json['type']);

    return ExerciseSuggestion(
      name: name.trim(),
      description: _requiredString(json, 'description'),
      type: type,
      contraindications: _requiredStringList(json, 'contraindications'),
      muscles: _requiredStringList(json, 'muscles'),
      instructions: _requiredString(json, 'instructions'),
      commonMistakes: _requiredStringList(json, 'commonMistakes'),
    );
  }

  /// Разбирает сырой текст ответа: сначала декодирует JSON, затем строго
  /// проверяет объект. Недопустимый JSON также даёт [MalformedSuggestionException].
  ExerciseSuggestion fromJsonString(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw MalformedSuggestionException(
        'Ответ не является корректным JSON: ${e.message}',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const MalformedSuggestionException('Ожидался JSON-объект');
    }
    return fromJson(decoded);
  }

  ExerciseType _parseType(Object? value) {
    if (value is! String) {
      throw const MalformedSuggestionException('"type" должен быть строкой');
    }
    for (final type in ExerciseType.values) {
      if (type.name == value) {
        return type;
      }
    }
    throw MalformedSuggestionException('Неизвестный "type": $value');
  }

  String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw MalformedSuggestionException('"$key" должен быть строкой');
    }
    return value;
  }

  List<String> _requiredStringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) {
      throw MalformedSuggestionException('"$key" должен быть массивом строк');
    }
    for (final item in value) {
      if (item is! String) {
        throw MalformedSuggestionException(
          '"$key" должен содержать только строки',
        );
      }
    }
    return value.cast<String>();
  }
}
