import 'package:signals/signals.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/domain/workout_controller.dart';
import 'package:fitnessappai/features/workout/domain/workout_exercise.dart';
import 'package:fitnessappai/features/workout/domain/workout_session_context.dart';
import 'package:fitnessappai/features/workout/domain/workout_set_input.dart';

/// Управляет экраном выполнения тренировки: загрузка дня по [programDayId],
/// запуск сессии через [WorkoutController] и сохранение результатов.
class WorkoutRunController {
  WorkoutRunController({
    required this.programRepository,
    required this.exerciseRepository,
    required this.workoutRepository,
    required this.programDayId,
    required this.variant,
    DateTime Function()? clock,
    TimerFactory? timerFactory,
    SoundService? soundService,
  }) : workout = WorkoutController(
         clock: clock,
         timerFactory: timerFactory,
         soundService: soundService,
       ) {
    _load();
  }

  /// Бизнес-логика сессии.
  final WorkoutController workout;
  final ProgramRepository programRepository;
  final ExerciseRepository exerciseRepository;
  final WorkoutRepository workoutRepository;
  final int programDayId;
  final WorkoutVariant variant;

  final Signal<bool> isLoading = Signal(true);
  final Signal<bool> notFound = Signal(false);
  final Signal<bool> emptyDay = Signal(false);
  final Signal<bool> saving = Signal(false);
  final Signal<bool> saved = Signal(false);

  WorkoutSessionDetail? _savedDetail;
  WorkoutSessionDetail? get savedDetail => _savedDetail;

  /// Суммарное число подходов для отображения прогресса.
  int get totalSets => workout.exercises.fold(0, (sum, e) => sum + e.sets);

  /// Длительность тренировки в минутах (минимум 1).
  ///
  /// До сохранения считается от старта сессии, после — из сохранённой сессии.
  int get durationMinutes {
    final session = _savedDetail?.session;
    final duration = session == null
        ? workout.elapsed()
        : session.endedAt.difference(session.startedAt);
    return duration.inMinutes.clamp(1, 1 << 31);
  }

  Future<void> _load() async {
    isLoading.value = true;
    notFound.value = false;
    emptyDay.value = false;
    try {
      final day = await programRepository.getDay(programDayId);
      if (day == null || day.id == null) {
        notFound.value = true;
        return;
      }
      final program = await programRepository.getById(day.programId);
      final all = await programRepository.getExercises(day.id!);
      final selected = all
          .where(
            (e) => e.isAlternative == (variant == WorkoutVariant.alternative),
          )
          .toList();
      if (selected.isEmpty) {
        emptyDay.value = true;
        return;
      }
      final exercises = <WorkoutExercise>[];
      for (final position in selected) {
        final exercise = position.exerciseId == null
            ? null
            : await exerciseRepository.getById(position.exerciseId!);
        if (exercise == null) {
          continue;
        }
        exercises.add(WorkoutExercise(position: position, exercise: exercise));
      }
      if (exercises.isEmpty) {
        emptyDay.value = true;
        return;
      }
      workout.start(
        exercises,
        context: WorkoutSessionContext(
          programId: program?.id,
          programName: program?.name ?? '',
          programDayId: day.id,
          dayIndex: day.dayIndex,
          variant: variant,
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Фиксирует введённые значения подхода.
  void confirmSet(WorkoutSetInput input) {
    workout.setResult(input);
    workout.confirmSet();
  }

  /// Завершает тренировку и сохраняет сессию с результатами.
  Future<void> completeAndSave() async {
    if (workout.phase.value != WorkoutPhase.finished) {
      return;
    }
    if (saved.value) {
      return;
    }
    final result = workout.completeWorkout();
    saving.value = true;
    try {
      _savedDetail = await workoutRepository.saveSession(
        result.session,
        result.results,
      );
      saved.value = true;
    } finally {
      saving.value = false;
    }
  }
}
