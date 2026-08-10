import 'dart:convert';

import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';

/// Упражнение из seed-файла.
class SeedExercise {
  const SeedExercise({
    required this.name,
    required this.type,
    required this.description,
    required this.instructions,
    required this.commonMistakes,
    required this.animation,
    required this.muscles,
    required this.contraindications,
  });

  final String name;
  final ExerciseType type;
  final String description;
  final String instructions;
  final List<String> commonMistakes;
  final String animation;
  final List<SeedExerciseMuscle> muscles;
  final List<String> contraindications;
}

/// Привязка мышцы к seed-упражнению по ключу справочника.
class SeedExerciseMuscle {
  const SeedExerciseMuscle({required this.key, required this.intensity});

  final String key;
  final MuscleIntensity intensity;
}

/// Разбирает `assets/data/exercises_seed.json`.
///
/// Устойчив к «грязному» JSON: пропускает записи без названия или
/// с неизвестным типом, невалидные мышцы, а недостающие строковые поля
/// заменяет пустыми значениями.
class ExerciseSeedParser {
  List<SeedExercise> parse(String source) {
    final decoded = jsonDecode(source);
    final list = decoded is Map<String, dynamic>
        ? decoded['exercises']
        : decoded;
    if (list is! List) {
      return const [];
    }

    final result = <SeedExercise>[];
    for (final item in list) {
      if (item is! Map) {
        continue;
      }
      final map = item.cast<String, dynamic>();
      final name = map['name'];
      final type = _parseType(map['type']);
      if (name is! String || name.trim().isEmpty || type == null) {
        continue;
      }
      result.add(_parseExercise(name.trim(), type, map));
    }
    return result;
  }

  SeedExercise _parseExercise(
    String name,
    ExerciseType type,
    Map<String, dynamic> map,
  ) {
    return SeedExercise(
      name: name,
      type: type,
      description: _asString(map['description']),
      instructions: _asString(map['instructions']),
      commonMistakes: _asStringList(map['commonMistakes']),
      animation: _asString(map['animation']),
      muscles: _parseMuscles(map['muscles']),
      contraindications: _asStringList(map['contraindications']),
    );
  }

  ExerciseType? _parseType(Object? value) {
    if (value is! String) {
      return null;
    }
    for (final type in ExerciseType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return null;
  }

  List<SeedExerciseMuscle> _parseMuscles(Object? value) {
    if (value is! List) {
      return const [];
    }
    final result = <SeedExerciseMuscle>[];
    for (final item in value) {
      if (item is! Map) {
        continue;
      }
      final map = item.cast<String, dynamic>();
      final key = map['key'];
      final intensity = _parseIntensity(map['intensity']);
      if (key is! String || key.isEmpty || intensity == null) {
        continue;
      }
      result.add(SeedExerciseMuscle(key: key, intensity: intensity));
    }
    return result;
  }

  MuscleIntensity? _parseIntensity(Object? value) {
    if (value is! String) {
      return null;
    }
    for (final intensity in MuscleIntensity.values) {
      if (intensity.name == value) {
        return intensity;
      }
    }
    return null;
  }

  String _asString(Object? value) => value is String ? value : '';

  List<String> _asStringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList();
  }
}
