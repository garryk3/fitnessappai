import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/features/llm/domain/exercise_suggestion.dart';
import 'package:fitnessappai/features/llm/domain/malformed_suggestion_exception.dart';
import 'package:fitnessappai/features/llm/domain/suggestion_json_parser.dart';

void main() {
  const parser = SuggestionJsonParser();

  Map<String, dynamic> validJson({
    String name = 'Приседания со штангой',
    String type = 'strength',
    String description = 'Базовое упражнение для ног',
    String instructions = 'Спина прямая.\nТаз назад.',
    List<String> commonMistakes = const ['Круглая спина'],
    List<String> muscles = const ['quads', 'glutes'],
    List<String> contraindications = const ['knees', 'back'],
  }) => {
    'name': name,
    'description': description,
    'type': type,
    'instructions': instructions,
    'commonMistakes': commonMistakes,
    'muscles': muscles,
    'contraindications': contraindications,
  };

  ExerciseSuggestion parsed() => parser.fromJson(validJson());

  group('SuggestionJsonParser.fromJson', () {
    test('разбирает валидный JSON во все поля', () {
      final suggestion = parsed();

      expect(suggestion.name, 'Приседания со штангой');
      expect(suggestion.description, 'Базовое упражнение для ног');
      expect(suggestion.type, ExerciseType.strength);
      expect(suggestion.instructions, 'Спина прямая.\nТаз назад.');
      expect(suggestion.commonMistakes, ['Круглая спина']);
      expect(suggestion.muscles, ['quads', 'glutes']);
      expect(suggestion.contraindications, ['knees', 'back']);
    });

    test('поддерживает plank и running', () {
      final plank = parser.fromJson(validJson(name: 'Планка', type: 'plank'));
      expect(plank.type, ExerciseType.plank);

      final run = parser.fromJson(validJson(name: 'Бег', type: 'running'));
      expect(run.type, ExerciseType.running);
    });

    test('обрезает пробелы вокруг названия', () {
      final suggestion = parser.fromJson(validJson(name: '  Жим  '));
      expect(suggestion.name, 'Жим');
    });

    test('игнорирует лишние поля', () {
      final json = validJson()
        ..['source'] = 'qwen'
        ..['language'] = 'ru'
        ..['extra_object'] = {'nested': true};

      final suggestion = parser.fromJson(json);

      expect(suggestion.name, 'Приседания со штангой');
    });

    test('пустые строковые поля допустимы', () {
      final suggestion = parser.fromJson(
        validJson(description: '', instructions: '', commonMistakes: []),
      );

      expect(suggestion.description, '');
      expect(suggestion.instructions, '');
      expect(suggestion.commonMistakes, isEmpty);
    });

    test('пустые списки мышц и противопоказаний допустимы', () {
      final suggestion = parser.fromJson(
        validJson(muscles: [], contraindications: []),
      );

      expect(suggestion.muscles, isEmpty);
      expect(suggestion.contraindications, isEmpty);
    });

    group('отклоняет невалидные значения с typed-ошибкой', () {
      test('пустое название', () {
        expect(
          () => parser.fromJson(validJson(name: '   ')),
          throwsA(
            isA<MalformedSuggestionException>().having(
              (e) => e.message,
              'message',
              contains('name'),
            ),
          ),
        );
      });

      test('неверный тип названия', () {
        expect(
          () => parser.fromJson(validJson()..['name'] = 42),
          throwsA(isA<MalformedSuggestionException>()),
        );
      });

      test('неизвестный тип упражнения', () {
        expect(
          () => parser.fromJson(validJson(type: 'yoga')),
          throwsA(
            isA<MalformedSuggestionException>().having(
              (e) => e.message,
              'message',
              contains('yoga'),
            ),
          ),
        );
      });

      test('число вместо строки в обязательных полях', () {
        expect(
          () => parser.fromJson(validJson()..['description'] = 12),
          throwsA(isA<MalformedSuggestionException>()),
        );
        expect(
          () => parser.fromJson(validJson()..['instructions'] = false),
          throwsA(isA<MalformedSuggestionException>()),
        );
      });

      test('не-массив вместо списков', () {
        expect(
          () => parser.fromJson(validJson()..['muscles'] = 'quads'),
          throwsA(isA<MalformedSuggestionException>()),
        );
        expect(
          () => parser.fromJson(validJson()..['contraindications'] = {}),
          throwsA(isA<MalformedSuggestionException>()),
        );
      });

      test('нестроковые элементы списков', () {
        expect(
          () => parser.fromJson(validJson()..['muscles'] = ['quads', 7]),
          throwsA(isA<MalformedSuggestionException>()),
        );
        expect(
          () => parser.fromJson(validJson()..['commonMistakes'] = [null]),
          throwsA(isA<MalformedSuggestionException>()),
        );
      });

      test('пропущенные обязательные поля', () {
        for (final key in [
          'name',
          'description',
          'type',
          'instructions',
          'commonMistakes',
          'muscles',
          'contraindications',
        ]) {
          final json = validJson()..remove(key);
          expect(
            () => parser.fromJson(json),
            throwsA(
              isA<MalformedSuggestionException>().having(
                (e) => e.message,
                'message',
                contains(key),
              ),
            ),
            reason: 'поле $key не может отсутствовать',
          );
        }
      });
    });
  });

  group('SuggestionJsonParser.fromJsonString', () {
    test('разбирает строку с валидным JSON', () {
      final suggestion = parser.fromJsonString(
        '{"name":"Бег","type":"running",'
        '"description":"","instructions":"","commonMistakes":[],'
        '"muscles":["calves"],"contraindications":[]}',
      );

      expect(suggestion.name, 'Бег');
      expect(suggestion.type, ExerciseType.running);
    });

    test('некорректный JSON даёт typed-ошибку', () {
      expect(
        () => parser.fromJsonString('не json'),
        throwsA(isA<MalformedSuggestionException>()),
      );
      expect(
        () => parser.fromJsonString(''),
        throwsA(isA<MalformedSuggestionException>()),
      );
    });

    test('JSON не в виде объекта отклоняется', () {
      expect(
        () => parser.fromJsonString('[]'),
        throwsA(isA<MalformedSuggestionException>()),
      );
      expect(
        () => parser.fromJsonString('"строка"'),
        throwsA(isA<MalformedSuggestionException>()),
      );
      expect(
        () => parser.fromJsonString('42'),
        throwsA(isA<MalformedSuggestionException>()),
      );
    });
  });

  test('ExerciseSuggestion: равенство и копирование не меняют поля', () {
    final a = parsed();
    final b = parser.fromJson(validJson());

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.toString(), contains('Приседания со штангой'));
  });
}
