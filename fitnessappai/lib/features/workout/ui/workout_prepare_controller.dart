import 'package:signals/signals.dart';

import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';

/// Позиция в подготовке: упражнение с параметрами из дня.
class WorkoutPrepareItem {
  const WorkoutPrepareItem({required this.exercise, required this.params});

  final Exercise exercise;
  final ProgramDayExercise params;
}

/// Управляет экраном подготовки: загрузка дня, выбор набора, старт.
class WorkoutPrepareController {
  WorkoutPrepareController({
    required this.programRepository,
    required this.exerciseRepository,
    required this.programDayId,
  }) {
    _load();
  }

  final ProgramRepository programRepository;
  final ExerciseRepository exerciseRepository;
  final int programDayId;

  final Signal<bool> isLoading = Signal(true);
  final Signal<bool> notFound = Signal(false);
  final Signal<String> programName = Signal('');
  final Signal<int> dayIndex = Signal(0);
  final Signal<WorkoutVariant> variant = Signal(WorkoutVariant.main);

  List<WorkoutPrepareItem> mainItems = [];
  List<WorkoutPrepareItem> alternativeItems = [];

  bool get hasAlternative => alternativeItems.isNotEmpty;

  List<WorkoutPrepareItem> get visibleItems =>
      variant.value == WorkoutVariant.alternative && hasAlternative
      ? alternativeItems
      : mainItems;

  Future<void> _load() async {
    isLoading.value = true;
    notFound.value = false;
    try {
      final day = await programRepository.getDay(programDayId);
      if (day == null || day.id == null) {
        notFound.value = true;
        return;
      }
      final program = await programRepository.getById(day.programId);
      programName.value = program?.name ?? '';
      dayIndex.value = day.dayIndex;
      final all = await programRepository.getExercises(day.id!);
      mainItems = await _resolve(all.where((e) => !e.isAlternative).toList());
      alternativeItems = await _resolve(
        all.where((e) => e.isAlternative).toList(),
      );
    } finally {
      isLoading.value = false;
    }
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
