import 'package:signals/signals.dart';

import 'package:fitnessappai/core/domain/models/contraindication_tag.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/profile/domain/contraindication_service.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';

/// Позиция в подготовке: упражнение с параметрами из дня.
class WorkoutPrepareItem {
  const WorkoutPrepareItem({required this.exercise, required this.params});

  final Exercise exercise;
  final ProgramDayExercise params;
}

/// Предупреждение о противопоказаниях для упражнения из текущего набора.
class WorkoutWarning {
  const WorkoutWarning({required this.exerciseName, required this.tagLabels});

  final String exerciseName;
  final List<String> tagLabels;
}

/// Управляет экраном подготовки: загрузка дня, выбор набора, старт.
class WorkoutPrepareController {
  WorkoutPrepareController({
    required this.programRepository,
    required this.exerciseRepository,
    required this.profileRepository,
    required this.programDayId,
    this.service = const ContraindicationService(),
  }) {
    _load();
  }

  final ProgramRepository programRepository;
  final ExerciseRepository exerciseRepository;
  final UserProfileRepository profileRepository;
  final ContraindicationService service;
  final int programDayId;

  final Signal<bool> isLoading = Signal(true);
  final Signal<bool> notFound = Signal(false);
  final Signal<String> programName = Signal('');
  final Signal<int?> programId = Signal(null);
  final Signal<int> dayIndex = Signal(0);
  final Signal<int?> warmupMinutes = Signal(null);
  final Signal<WorkoutVariant> variant = Signal(WorkoutVariant.main);

  List<WorkoutPrepareItem> mainItems = [];
  List<WorkoutPrepareItem> alternativeItems = [];

  Set<String> _userKeys = const {};
  Map<int, List<ContraindicationTag>> _tagsByExercise = const {};

  bool get hasAlternative => alternativeItems.isNotEmpty;

  List<WorkoutPrepareItem> get visibleItems =>
      variant.value == WorkoutVariant.alternative && hasAlternative
      ? alternativeItems
      : mainItems;

  /// Упражнения текущего набора с противопоказаниями для пользователя.
  List<WorkoutWarning> get visibleWarnings {
    return [
      for (final item in visibleItems)
        if (_warningsFor(item) case final tags? when tags.isNotEmpty)
          WorkoutWarning(exerciseName: item.exercise.name, tagLabels: tags),
    ];
  }

  Future<void> _load() async {
    isLoading.value = true;
    notFound.value = false;
    try {
      final day = await programRepository.getDay(programDayId);
      if (day == null || day.id == null) {
        notFound.value = true;
        return;
      }
      programId.value = day.programId;
      final program = await programRepository.getById(day.programId);
      programName.value = program?.name ?? '';
      dayIndex.value = day.dayIndex;
      warmupMinutes.value = day.warmupMinutes;
      _tagsByExercise = await exerciseRepository.contraindicationsByExercise();
      _userKeys = {
        for (final tag in await profileRepository.getContraindicationTags())
          tag.key,
      };
      final all = await programRepository.getExercises(day.id!);
      mainItems = await _resolve(all.where((e) => !e.isAlternative).toList());
      alternativeItems = await _resolve(
        all.where((e) => e.isAlternative).toList(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  List<String>? _warningsFor(WorkoutPrepareItem item) {
    final tags = _tagsByExercise[item.exercise.id] ?? const [];
    final intersecting = service.intersectingTags(tags, _userKeys);
    return intersecting.isEmpty
        ? null
        : [for (final tag in intersecting) tag.labelRu];
  }

  Future<List<WorkoutPrepareItem>> _resolve(
    List<ProgramDayExercise> params,
  ) async {
    final result = <WorkoutPrepareItem>[];
    for (final p in params) {
      final exercise = p.exerciseId == null
          ? null
          : await exerciseRepository.getById(p.exerciseId!);
      if (exercise == null) {
        continue;
      }
      result.add(WorkoutPrepareItem(exercise: exercise, params: p));
    }
    return result;
  }
}
