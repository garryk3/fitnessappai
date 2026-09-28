/// Тип упражнения. Определяет метрики, которые фиксируются на подходе.
///
/// Тип `distance` объединил прежние «бег» и «велосипед» (задача 47.13):
/// метрики у них одинаковые (дистанция + время), различались только
/// необязательные поля ввода (темп/шаги против скорости/каденса/пульса/
/// перепада высот), которые теперь доступны всем упражнениям этого типа.
enum ExerciseType { strength, bodyweight, plank, distance }

/// Устаревшие имена типов, объединённых в [ExerciseType.distance] (47.13).
const Map<String, ExerciseType> legacyExerciseTypes = {
  'running': ExerciseType.distance,
  'bike': ExerciseType.distance,
};

/// Разбирает имя типа упражнения, принимая устаревшие `running` и `bike`
/// как [ExerciseType.distance] (задача 47.13).
///
/// Возвращает `null` для неизвестных строк: вызывающий сам решает, что с
/// ними делать (seed пропускает упражнение, парсер подсказок LLM — ругается).
ExerciseType? exerciseTypeFromName(String name) {
  for (final type in ExerciseType.values) {
    if (type.name == name) {
      return type;
    }
  }
  return legacyExerciseTypes[name];
}
