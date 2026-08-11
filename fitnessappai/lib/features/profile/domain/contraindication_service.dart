import 'package:fitnessappai/core/domain/models/contraindication_tag.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';

/// Чистая бизнес-логика противопоказаний.
///
/// Сравнивает теги противопоказаний упражнения с тегами пользователя и
/// возвращает предупреждения либо отфильтрованные упражнения.
class ContraindicationService {
  const ContraindicationService();

  /// Теги упражнения, пересекающиеся с тегами пользователя.
  List<ContraindicationTag> intersectingTags(
    List<ContraindicationTag> exerciseTags,
    Set<String> userTagKeys,
  ) {
    if (userTagKeys.isEmpty) {
      return const [];
    }
    return exerciseTags
        .where((t) => userTagKeys.contains(t.key))
        .toList(growable: false);
  }

  /// Сообщения о противопоказаниях для упражнения (по labelRu совпавших тегов).
  List<String> warningsFor(
    List<ContraindicationTag> exerciseTags,
    Set<String> userTagKeys,
  ) {
    return [
      for (final tag in intersectingTags(exerciseTags, userTagKeys))
        tag.labelRu,
    ];
  }

  /// Есть ли у упражнения противопоказания, пересекающиеся с тегами пользователя.
  bool hasContraindications(
    List<ContraindicationTag> exerciseTags,
    Set<String> userTagKeys,
  ) {
    return intersectingTags(exerciseTags, userTagKeys).isNotEmpty;
  }

  /// Оставляет упражнения без пересечения противопоказаний с [userTagKeys].
  ///
  /// [tagsByExerciseId] — карта «id упражнения → его теги противопоказаний».
  /// Упражнения без записи в карте считаются допустимыми.
  List<Exercise> filterAllowed(
    List<Exercise> exercises,
    Map<int, List<ContraindicationTag>> tagsByExerciseId,
    Set<String> userTagKeys,
  ) {
    return exercises
        .where((e) {
          final tags = tagsByExerciseId[e.id];
          return tags == null || !hasContraindications(tags, userTagKeys);
        })
        .toList(growable: false);
  }
}
