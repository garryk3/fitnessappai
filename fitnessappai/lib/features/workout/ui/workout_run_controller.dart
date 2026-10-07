import 'dart:developer';

import 'package:signals/signals.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/models/single_exercise_params.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/domain/workout_checkpoint.dart';
import 'package:fitnessappai/features/workout/domain/workout_controller.dart';
import 'package:fitnessappai/features/workout/domain/workout_exercise.dart';
import 'package:fitnessappai/features/workout/domain/workout_session_context.dart';
import 'package:fitnessappai/features/workout/domain/workout_set_input.dart';

/// Управляет экраном выполнения тренировки: загрузка дня по [programDayId]
/// или одиночного упражнения по [exerciseId], запуск сессии через
/// [WorkoutController] и сохранение результатов.
class WorkoutRunController {
  WorkoutRunController({
    required this.programRepository,
    required this.exerciseRepository,
    required this.workoutRepository,
    this.programDayId,
    this.variant,
    this.exerciseId,
    this.singleExerciseParams,
    this.rescheduleWeekStart,
    DateTime Function()? clock,
    TimerFactory? timerFactory,
    SoundService? soundService,
  }) : assert(
         (programDayId != null) != (exerciseId != null),
         'Укажите либо programDayId, либо exerciseId',
       ),
       workout = WorkoutController(
         clock: clock,
         timerFactory: timerFactory,
         soundService: soundService,
       );

  /// Бизнес-логика сессии.
  final WorkoutController workout;
  final ProgramRepository programRepository;
  final ExerciseRepository exerciseRepository;
  final WorkoutRepository workoutRepository;
  final int? programDayId;
  final WorkoutVariant? variant;
  final int? exerciseId;

  /// Параметры одиночного упражнения из экрана [SingleExerciseParamsScreen].
  final SingleExerciseParams? singleExerciseParams;

  /// Понедельник недели-источника, если тренировка запущена как перенос
  /// («Перенести на сегодня», задача 48.4).
  ///
  /// Отметка `rescheduled` ставится **не при тапе**, а только после
  /// фактического сохранения сессии (см. [completeAndSave]) — иначе день-
  /// источник пустел ещё до выполнения тренировки. `null` — тренировка
  /// запущена не как перенос, отметка не нужна. Mutable: значение подхватывается
  /// из чекпоинта при восстановлении после убийства процесса ОС.
  DateTime? rescheduleWeekStart;

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

  /// Загружает данные тренировки. Вызывать ровно 1 раз после построения
  /// экрана. Если передан [checkpoint], восстанавливает состояние из него
  /// вместо запуска новой сессии.
  Future<void> load({WorkoutCheckpoint? checkpoint}) async {
    // Восстановление после убийства процесса: параметр переноса жил только в
    // query-строке и при перенаправлении из чекпоинта потерялся бы (48.4).
    if (checkpoint != null && rescheduleWeekStart == null) {
      rescheduleWeekStart = checkpoint.rescheduleWeekStart;
    }
    isLoading.value = true;
    notFound.value = false;
    emptyDay.value = false;
    try {
      if (exerciseId != null) {
        await _loadSingleExercise(exerciseId!, checkpoint: checkpoint);
      } else {
        await _loadFromProgram(programDayId!, variant!, checkpoint: checkpoint);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSingleExercise(
    int id, {
    WorkoutCheckpoint? checkpoint,
  }) async {
    final exercise = await exerciseRepository.getById(id);
    if (exercise == null) {
      notFound.value = true;
      return;
    }
    final params = singleExerciseParams;
    final position = ProgramDayExercise(
      dayId: 0,
      exerciseId: exercise.id,
      orderIndex: 0,
      sets: params?.sets ?? 3,
      reps: params?.reps ?? 10,
      weightKg: params?.weightKg,
      durationSeconds: params?.durationSeconds,
      distanceMeters: params?.distanceMeters,
      restSeconds: params?.restSeconds ?? 60,
    );
    final exercises = [WorkoutExercise(position: position, exercise: exercise)];
    if (checkpoint != null) {
      workout.restoreFromCheckpoint(checkpoint, exercises);
    } else {
      workout.start(
        exercises,
        context: WorkoutSessionContext(programName: exercise.name, dayIndex: 0),
      );
    }
  }

  Future<void> _loadFromProgram(
    int dayId,
    WorkoutVariant variant, {
    WorkoutCheckpoint? checkpoint,
  }) async {
    final day = await programRepository.getDay(dayId);
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
    if (checkpoint != null) {
      workout.restoreFromCheckpoint(checkpoint, exercises);
    } else {
      workout.start(
        exercises,
        context: WorkoutSessionContext(
          programId: program?.id,
          programName: program?.name ?? '',
          programDayId: day.id,
          dayIndex: day.dayIndex,
          variant: variant,
          exerciseRestSeconds: program?.exerciseRestSeconds,
        ),
      );
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
      await _markRescheduledIfAny();
      saved.value = true;
    } finally {
      saving.value = false;
    }
  }

  /// Помечает исходный день перенесённым — только по факту сохранения сессии.
  ///
  /// Раньше отметка ставилась при тапе «Перенести на сегодня», и день-источник
  /// пустел ещё до выполнения тренировки (задача 48.4). Выход без завершения
  /// ничего не пишет: исходный день остаётся запланированным.
  ///
  /// Ошибка отметки не должна ломать уже сохранённую сессию — план догонит
  /// статус по сессии (47.1).
  Future<void> _markRescheduledIfAny() async {
    final dayId = programDayId;
    final weekStart = rescheduleWeekStart;
    if (dayId == null || weekStart == null) {
      return;
    }
    try {
      // День могли удалить, пока тренировка шла: отметка ссылается на него по
      // FK, поэтому сначала убеждаемся, что день ещё есть.
      if (await programRepository.getDay(dayId) == null) {
        return;
      }
      await workoutRepository.markRescheduled(dayId, weekStart);
    } catch (e, st) {
      log(
        'Не удалось пометить перенос дня $dayId на неделе $weekStart',
        error: e,
        stackTrace: st,
      );
    }
  }
}
