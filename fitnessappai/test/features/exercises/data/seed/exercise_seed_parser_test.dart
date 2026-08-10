import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/features/exercises/data/seed/exercise_seed_parser.dart';

void main() {
  final parser = ExerciseSeedParser();

  test('парсит реальный seed JSON', () {
    final source = File('assets/data/exercises_seed.json').readAsStringSync();
    final exercises = parser.parse(source);
    expect(exercises.length, greaterThanOrEqualTo(15));
    expect(
      exercises.map((e) => e.type).toSet(),
      containsAll(ExerciseType.values),
    );
    for (final e in exercises) {
      expect(e.name, isNotEmpty);
      expect(e.animation, isNotEmpty);
      expect(e.muscles, isNotEmpty);
    }
    final squat = exercises.firstWhere(
      (e) => e.name == 'Приседания со штангой',
    );
    expect(squat.muscles.map((m) => m.key), contains('quads'));
    expect(squat.contraindications, containsAll(['knees', 'back']));
    expect(squat.instructions, isNotEmpty);
  });

  test('пропускает записи без названия', () {
    final source = jsonEncode({
      'exercises': [
        {'name': '', 'type': 'strength'},
        {'type': 'strength'},
        {'name': 'Планка', 'type': 'plank'},
      ],
    });
    final exercises = parser.parse(source);
    expect(exercises.single.name, 'Планка');
  });

  test('пропускает записи с неизвестным типом', () {
    final source = jsonEncode({
      'exercises': [
        {'name': 'Неизвестный', 'type': 'yoga'},
        {'name': 'Бег', 'type': 'running'},
      ],
    });
    final exercises = parser.parse(source);
    expect(exercises.single.type, ExerciseType.running);
  });

  test('заполняет отсутствующие строковые поля пустыми значениями', () {
    final source = jsonEncode({
      'exercises': [
        {'name': 'Планка', 'type': 'plank'},
      ],
    });
    final exercise = parser.parse(source).single;
    expect(exercise.description, '');
    expect(exercise.instructions, '');
    expect(exercise.commonMistakes, isEmpty);
    expect(exercise.animation, '');
    expect(exercise.contraindications, isEmpty);
    expect(exercise.muscles, isEmpty);
  });

  test('пропускает невалидные мышцы и нестроковые элементы списков', () {
    final source = jsonEncode({
      'exercises': [
        {
          'name': 'Жим',
          'type': 'strength',
          'commonMistakes': ['отрыв таза', 42, null],
          'contraindications': ['knees', 7],
          'muscles': [
            {'key': 'chest', 'intensity': 'primary'},
            {'key': 'unknown', 'intensity': 'primary'},
            {'key': '', 'intensity': 'primary'},
            {'key': 'shoulders', 'intensity': 'huge'},
            {'key': 'triceps'},
            'garbage',
          ],
        },
      ],
    });
    final muscles = parser.parse(source).single.muscles;
    expect(muscles, hasLength(2));
    expect(muscles.first.key, 'chest');
    expect(muscles.first.intensity, MuscleIntensity.primary);
    expect(muscles.last.key, 'unknown');
    expect(parser.parse(source).single.commonMistakes, ['отрыв таза']);
    expect(parser.parse(source).single.contraindications, ['knees']);
  });

  test('возвращает пустой список для JSON без списка упражнений', () {
    expect(parser.parse('{"version": 1}'), isEmpty);
    expect(parser.parse('"строка"'), isEmpty);
    expect(parser.parse('null'), isEmpty);
  });
}
