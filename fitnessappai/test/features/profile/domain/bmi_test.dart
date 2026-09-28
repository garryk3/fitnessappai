import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/features/profile/domain/bmi.dart';

void main() {
  group('calculateBmi', () {
    test('70 кг при 175 см → 22.9', () {
      expect(calculateBmi(weightKg: 70, heightCm: 175), closeTo(22.86, 0.01));
    });

    test('без веса или роста → null', () {
      expect(calculateBmi(weightKg: null, heightCm: 175), isNull);
      expect(calculateBmi(weightKg: 70, heightCm: null), isNull);
      expect(calculateBmi(weightKg: null, heightCm: null), isNull);
    });

    test('неположительные значения → null', () {
      expect(calculateBmi(weightKg: 0, heightCm: 175), isNull);
      expect(calculateBmi(weightKg: 70, heightCm: 0), isNull);
      expect(calculateBmi(weightKg: -70, heightCm: 175), isNull);
      expect(calculateBmi(weightKg: 70, heightCm: -175), isNull);
    });
  });

  group('bmiCategoryFor (границы)', () {
    test('мужчины: норма 18.5–25', () {
      expect(
        bmiCategoryFor(value: 18.4, gender: Gender.male),
        BmiCategory.underweight,
      );
      expect(
        bmiCategoryFor(value: 18.5, gender: Gender.male),
        BmiCategory.normal,
      );
      expect(
        bmiCategoryFor(value: 24.9, gender: Gender.male),
        BmiCategory.normal,
      );
      expect(
        bmiCategoryFor(value: 25, gender: Gender.male),
        BmiCategory.overweight,
      );
    });

    test('женщины: норма 19–24', () {
      expect(
        bmiCategoryFor(value: 18.9, gender: Gender.female),
        BmiCategory.underweight,
      );
      expect(
        bmiCategoryFor(value: 19, gender: Gender.female),
        BmiCategory.normal,
      );
      expect(
        bmiCategoryFor(value: 23.9, gender: Gender.female),
        BmiCategory.normal,
      );
      // Верхняя граница нормы исключающая (по ВОЗ: 18.5–24.9 / 19–23.9).
      expect(
        bmiCategoryFor(value: 24, gender: Gender.female),
        BmiCategory.overweight,
      );
    });

    test('ожирение с 30 для обоих полов', () {
      expect(
        bmiCategoryFor(value: 29.9, gender: Gender.male),
        BmiCategory.overweight,
      );
      expect(bmiCategoryFor(value: 30, gender: Gender.male), BmiCategory.obese);
      expect(
        bmiCategoryFor(value: 29.9, gender: Gender.female),
        BmiCategory.overweight,
      );
      expect(
        bmiCategoryFor(value: 30, gender: Gender.female),
        BmiCategory.obese,
      );
    });

    test('одно значение ИМТ по-разному для мужчин и женщин', () {
      expect(
        bmiCategoryFor(value: 24.5, gender: Gender.male),
        BmiCategory.normal,
      );
      expect(
        bmiCategoryFor(value: 24.5, gender: Gender.female),
        BmiCategory.overweight,
      );
    });
  });

  group('границы шкалы', () {
    test('нижняя/верхняя граница нормы по полу', () {
      expect(normalBmiLowerBound(Gender.male), 18.5);
      expect(normalBmiUpperBound(Gender.male), 25);
      expect(normalBmiLowerBound(Gender.female), 19);
      expect(normalBmiUpperBound(Gender.female), 24);
      expect(obeseBmiBound, 30);
    });
  });

  group('genderFromStorage', () {
    test('известные значения', () {
      expect(genderFromStorage('male'), Gender.male);
      expect(genderFromStorage('female'), Gender.female);
    });

    test('пустое и незнакомое значение → null', () {
      expect(genderFromStorage(null), isNull);
      expect(genderFromStorage(''), isNull);
      expect(genderFromStorage('other'), isNull);
    });
  });
}
