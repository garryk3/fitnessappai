/// Пол пользователя. Хранится в `user_profiles.gender` строкой
/// ('male' / 'female'); используется для пол-специфичных шкал (ИМТ).
enum Gender {
  male('male'),
  female('female');

  const Gender(this.storageValue);

  /// Значение в колонке `user_profiles.gender`.
  final String storageValue;
}

/// Разбирает значение из БД; `null` для пустых и незнакомых строк.
Gender? genderFromStorage(String? value) => switch (value) {
  'male' => Gender.male,
  'female' => Gender.female,
  _ => null,
};

/// Категория индекса массы тела (классификация ВОЗ для взрослых).
enum BmiCategory {
  underweight('Низкая масса'),
  normal('Норма'),
  overweight('Избыточная масса'),
  obese('Ожирение');

  const BmiCategory(this.labelRu);

  /// Подпись категории (локализуется в UI через l10n).
  final String labelRu;
}

/// Нижняя граница нормы: мужчины — 18.5, женщины — 19.
double normalBmiLowerBound(Gender gender) =>
    gender == Gender.male ? 18.5 : 19.0;

/// Верхняя граница нормы: мужчины — 25, женщины — 24 (значение на границе уже
/// относится к избыточной массе: по ВОЗ норма 18.5–24.9 / 19–23.9).
double normalBmiUpperBound(Gender gender) =>
    gender == Gender.male ? 25.0 : 24.0;

/// Граница ожирения (общая для обоих полов).
const double obeseBmiBound = 30.0;

/// Индекс массы тела: [weightKg] / (рост в метрах)².
///
/// `null`, если вес или рост не заданы либо значения неположительные.
double? calculateBmi({required double? weightKg, required double? heightCm}) {
  if (weightKg == null || heightCm == null) {
    return null;
  }
  if (weightKg <= 0 || heightCm <= 0) {
    return null;
  }
  final heightM = heightCm / 100;
  return weightKg / (heightM * heightM);
}

/// Категория ИМТ [value] с учётом пола.
BmiCategory bmiCategoryFor({required double value, required Gender gender}) {
  if (value < normalBmiLowerBound(gender)) {
    return BmiCategory.underweight;
  }
  if (value < normalBmiUpperBound(gender)) {
    return BmiCategory.normal;
  }
  if (value < obeseBmiBound) {
    return BmiCategory.overweight;
  }
  return BmiCategory.obese;
}
