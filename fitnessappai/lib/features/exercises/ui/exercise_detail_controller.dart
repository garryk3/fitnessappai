import 'package:collection/collection.dart';
import 'package:signals/signals.dart';

import 'package:fitnessappai/core/domain/models/contraindication_tag.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/profile/domain/contraindication_service.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';

/// Данные деталей упражнения: сама модель, подсветка мышц и противопоказания.
class ExerciseDetailData {
  const ExerciseDetailData({
    required this.exercise,
    required this.highlights,
    required this.muscles,
    required this.contraindications,
    required this.userWarnings,
  });

  final Exercise exercise;

  /// `regionKey → интенсивность 0..1` для [MuscleDiagram].
  final Map<String, double> highlights;
  final List<MuscleGroup> muscles;
  final List<ContraindicationTag> contraindications;

  /// Теги противопоказаний, пересекающиеся с профилем пользователя.
  final List<ContraindicationTag> userWarnings;

  bool get hasMuscles => muscles.isNotEmpty;
  bool get hasContraindications => contraindications.isNotEmpty;
  bool get hasUserWarnings => userWarnings.isNotEmpty;
}

/// Управляет загрузкой данных экрана деталей упражнения.
class ExerciseDetailController {
  ExerciseDetailController(
    this._repository,
    this.exerciseId, {
    required this.profileRepository,
    this.service = const ContraindicationService(),
  });

  final ExerciseRepository _repository;
  final int exerciseId;
  final UserProfileRepository profileRepository;
  final ContraindicationService service;

  final Signal<ExerciseDetailData?> data = Signal(null);
  final Signal<bool> isLoading = Signal(true);

  Future<void> load() async {
    isLoading.value = true;
    try {
      final exercise = await _repository.getById(exerciseId);
      if (exercise == null) {
        data.value = null;
        return;
      }
      final exerciseMuscles = await _repository.getMuscles(exerciseId);
      final groups = await _repository.muscleGroupsByExercise();
      final contraindications = await _repository.getContraindications(
        exerciseId,
      );
      final userKeys = {
        for (final tag in await profileRepository.getContraindicationTags())
          tag.key,
      };

      final highlights = <String, double>{};
      final muscles = <MuscleGroup>[];
      for (final link in exerciseMuscles) {
        final group = groups[exerciseId]?.firstWhereOrNull(
          (g) => g.id == link.muscleGroupId,
        );
        if (group == null) {
          continue;
        }
        muscles.add(group);
        final intensity = link.intensity == MuscleIntensity.primary ? 1.0 : 0.5;
        highlights[group.regionKey] = highlights[group.regionKey]
            .clampIntensity(intensity);
      }

      data.value = ExerciseDetailData(
        exercise: exercise,
        highlights: highlights,
        muscles: muscles,
        contraindications: contraindications,
        userWarnings: service.intersectingTags(contraindications, userKeys),
      );
    } finally {
      isLoading.value = false;
    }
  }
}

extension on double? {
  /// Возвращает максимум текущего значения и [value].
  double clampIntensity(double value) {
    final current = this ?? 0.0;
    return current > value ? current : value;
  }
}
