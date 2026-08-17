import 'dart:async';

import 'package:signals/signals.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/domain/validators/program_day_exercise_validator.dart';
import 'package:fitnessappai/features/workout/domain/workout_exercise.dart';
import 'package:fitnessappai/features/workout/domain/workout_session_context.dart';
import 'package:fitnessappai/features/workout/domain/workout_set_input.dart';

/// Фаза тренировочной сессии.
enum WorkoutPhase { idle, exercise, rest, finished }

/// Бросается при попытке выполнить недопустимое действие (например,
/// подтвердить пустой подход или завершить незавершённую тренировку).
class WorkoutStateException implements Exception {
  WorkoutStateException(this.errors);

  final List<String> errors;

  @override
  String toString() => 'WorkoutStateException($errors)';
}

/// Создаёт таймер. Позволяет подменять реализацию в тестах.
typedef TimerFactory =
    Timer Function(Duration duration, void Function(Timer timer) callback);

/// Чистая бизнес-логика тренировочной сессии без зависимостей от UI.
///
/// Управляет переходами между упражнениями и подходами, отсчитывает отдых
/// и время удержания для планки, накапливает результаты подходов.
class WorkoutController {
  WorkoutController({
    DateTime Function()? clock,
    TimerFactory? timerFactory,
    SoundService? soundService,
  }) : _clock = clock ?? DateTime.now,
       _timerFactory = timerFactory ?? _defaultTimerFactory,
       // ignore: prefer_initializing_formals -- имя параметра публичное, поле приватное.
       _soundService = soundService;

  static Timer _defaultTimerFactory(
    Duration duration,
    void Function(Timer timer) callback,
  ) {
    return Timer.periodic(duration, callback);
  }

  final DateTime Function() _clock;
  final TimerFactory _timerFactory;
  final SoundService? _soundService;

  static final ProgramDayExerciseValidator _validator =
      ProgramDayExerciseValidator();

  final Signal<WorkoutPhase> phase = Signal(WorkoutPhase.idle);
  final Signal<int> currentExerciseIndex = Signal(0);
  final Signal<int> currentSet = Signal(1);
  final Signal<int> completedSets = Signal(0);
  final Signal<List<WorkoutSetResult>> results = Signal(<WorkoutSetResult>[]);
  final Signal<int?> restRemainingSeconds = Signal(null);

  /// Время удержания планки, прошедшее с начала отсчёта (0 — не запущен).
  final Signal<int> holdElapsedSeconds = Signal(0);

  /// Целевая длительность удержания планки (null — упражнение не планка).
  final Signal<int?> holdTargetSeconds = Signal(null);

  /// Идёт ли отсчёт удержания планки (запущен кнопкой «Начать»).
  final Signal<bool> holdRunning = Signal(false);

  final List<WorkoutExercise> _exercises = [];
  WorkoutSessionContext? _context;
  WorkoutSetInput? _draft;
  DateTime? _startedAt;
  Timer? _restTimer;
  Timer? _holdTimer;

  /// Неизменяемый список упражнений текущей сессии.
  List<WorkoutExercise> get exercises => List.unmodifiable(_exercises);

  WorkoutExercise? get currentExercise {
    if (_exercises.isEmpty || currentExerciseIndex.value >= _exercises.length) {
      return null;
    }
    return _exercises[currentExerciseIndex.value];
  }

  bool get isLastExercise =>
      currentExerciseIndex.value == _exercises.length - 1;

  /// Время с начала тренировки (до завершения или отмены).
  Duration elapsed() {
    final started = _startedAt;
    if (started == null) {
      return Duration.zero;
    }
    return _clock().difference(started);
  }

  WorkoutSessionContext? get context => _context;
  WorkoutSetInput? get draft => _draft;

  /// Начинает тренировку. Сбрасывает состояние и запускает счётчик удержания,
  /// если первое упражнение — планка.
  void start(
    List<WorkoutExercise> exercises, {
    WorkoutSessionContext? context,
  }) {
    if (exercises.isEmpty) {
      throw WorkoutStateException(const ['Нет упражнений для тренировки']);
    }
    _cancelTimers();
    _exercises
      ..clear()
      ..addAll(exercises);
    _context = context;
    _draft = null;
    _startedAt = _clock();
    phase.value = WorkoutPhase.exercise;
    currentExerciseIndex.value = 0;
    currentSet.value = 1;
    completedSets.value = 0;
    results.value = [];
    restRemainingSeconds.value = null;
    _prepareHoldTimer();
  }

  /// Сохраняет введённые значения текущего подхода.
  void setResult(WorkoutSetInput input) {
    _requireInExercise();
    _draft = input;
  }

  /// Возвращает ошибки валидации текущего ввода (пусто — ввод валиден).
  List<String> validateDraft() {
    if (currentExercise == null) {
      return const ['Тренировка не начата'];
    }
    return _validate(currentExercise!, _draft ?? const WorkoutSetInput());
  }

  /// Фиксирует подход и переходит к отдыху, следующему подходу/упражнению
  /// или завершению тренировки.
  void confirmSet() {
    _requireInExercise();
    final exercise = currentExercise!;
    final input = _draft ?? const WorkoutSetInput();
    final errors = _validate(exercise, input);
    if (errors.isNotEmpty) {
      throw WorkoutStateException(errors);
    }

    _holdTimer?.cancel();
    _holdTimer = null;
    holdRunning.value = false;
    holdElapsedSeconds.value = 0;
    holdTargetSeconds.value = null;
    _draft = null;

    results.value = [...results.value, _buildResult(exercise, input, _clock())];
    completedSets.value++;

    if (currentSet.value < exercise.sets) {
      currentSet.value++;
      _startRest(exercise.restSeconds);
    } else if (!isLastExercise) {
      currentExerciseIndex.value++;
      currentSet.value = 1;
      phase.value = WorkoutPhase.exercise;
      _prepareHoldTimer();
    } else {
      phase.value = WorkoutPhase.finished;
    }
  }

  /// Начинает отдых текущего упражнения (если он задан).
  void startRest() {
    _requireActive();
    final rest = currentExercise?.restSeconds ?? 0;
    if (phase.value == WorkoutPhase.exercise && rest > 0) {
      _startRest(rest);
    }
  }

  /// Пропускает отдых и возвращается к выполнению подхода.
  void skipRest() {
    if (phase.value != WorkoutPhase.rest) {
      return;
    }
    _restTimer?.cancel();
    _restTimer = null;
    restRemainingSeconds.value = null;
    phase.value = WorkoutPhase.exercise;
    _prepareHoldTimer();
  }

  /// Переходит к следующему упражнению, пропуская оставшийся отдых.
  void nextExercise() {
    _requireActive();
    if (isLastExercise || phase.value == WorkoutPhase.finished) {
      return;
    }
    _restTimer?.cancel();
    _restTimer = null;
    restRemainingSeconds.value = null;
    currentExerciseIndex.value++;
    currentSet.value = 1;
    phase.value = WorkoutPhase.exercise;
    _prepareHoldTimer();
  }

  /// Завершает тренировку и возвращает сессию с результатами.
  ///
  /// Доступно только в фазе [WorkoutPhase.finished]. Идентификатор сессии
  /// в результатах не заполнен — его присваивает репозиторий при сохранении.
  ({WorkoutSession session, List<WorkoutSetResult> results}) completeWorkout() {
    if (phase.value != WorkoutPhase.finished) {
      throw WorkoutStateException(const ['Тренировка не завершена']);
    }
    _cancelTimers();
    final context =
        _context ?? const WorkoutSessionContext(programName: '', dayIndex: 0);
    final started = _startedAt ?? _clock();
    final ended = _clock();
    final session = WorkoutSession(
      programId: context.programId,
      programName: context.programName,
      programDayId: context.programDayId,
      dayIndex: context.dayIndex,
      variant: context.variant,
      performedDate: DateTime(started.year, started.month, started.day),
      startedAt: started,
      endedAt: ended,
    );
    return (session: session, results: List.of(results.value));
  }

  /// Отменяет тренировку, ничего не сохраняя. Сбрасывает состояние.
  void cancelWorkout() {
    _cancelTimers();
    _exercises.clear();
    _context = null;
    _draft = null;
    _startedAt = null;
    phase.value = WorkoutPhase.idle;
    currentExerciseIndex.value = 0;
    currentSet.value = 1;
    completedSets.value = 0;
    results.value = [];
    restRemainingSeconds.value = null;
    holdRunning.value = false;
    holdElapsedSeconds.value = 0;
    holdTargetSeconds.value = null;
  }

  void dispose() {
    _cancelTimers();
  }

  void _startRest(int restSeconds) {
    if (restSeconds <= 0) {
      phase.value = WorkoutPhase.exercise;
      _prepareHoldTimer();
      return;
    }
    phase.value = WorkoutPhase.rest;
    restRemainingSeconds.value = restSeconds;
    _restTimer?.cancel();
    _restTimer = _timerFactory(const Duration(seconds: 1), (timer) {
      final remaining = (restRemainingSeconds.value ?? 0) - 1;
      if (remaining <= 0) {
        timer.cancel();
        _restTimer = null;
        restRemainingSeconds.value = null;
        phase.value = WorkoutPhase.exercise;
        _prepareHoldTimer();
        _soundService?.playCompletion();
      } else {
        restRemainingSeconds.value = remaining;
      }
    });
  }

  /// Подготавливает счётчик удержания планки: сбрасывает значение и задаёт
  /// цель текущего упражнения. Таймер не запускается — старт только по
  /// [startHoldTimer].
  void _prepareHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
    holdRunning.value = false;
    holdElapsedSeconds.value = 0;
    holdTargetSeconds.value = null;
    final exercise = currentExercise;
    if (exercise == null ||
        exercise.type != ExerciseType.plank ||
        phase.value != WorkoutPhase.exercise) {
      return;
    }
    final duration = exercise.position.durationSeconds;
    if (duration == null || duration <= 0) {
      return;
    }
    holdTargetSeconds.value = duration;
  }

  /// Запускает отсчёт удержания планки (кнопка «Начать»). Считает вверх
  /// от нуля и продолжает после цели, чтобы фактическое время удержания
  /// попало в результат.
  void startHoldTimer() {
    if (phase.value != WorkoutPhase.exercise ||
        holdTargetSeconds.value == null ||
        holdRunning.value) {
      return;
    }
    holdElapsedSeconds.value = 0;
    holdRunning.value = true;
    _holdTimer?.cancel();
    _holdTimer = _timerFactory(const Duration(seconds: 1), (timer) {
      holdElapsedSeconds.value++;
    });
  }

  WorkoutSetResult _buildResult(
    WorkoutExercise exercise,
    WorkoutSetInput input,
    DateTime now,
  ) {
    switch (exercise.type) {
      case ExerciseType.strength:
        return WorkoutSetResult(
          sessionId: 0,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          exerciseType: exercise.type,
          setIndex: currentSet.value,
          reps: input.reps,
          weightKg: input.weightKg,
          completedAt: now,
        );
      case ExerciseType.bodyweight:
        return WorkoutSetResult(
          sessionId: 0,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          exerciseType: exercise.type,
          setIndex: currentSet.value,
          reps: input.reps,
          completedAt: now,
        );
      case ExerciseType.plank:
        return WorkoutSetResult(
          sessionId: 0,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          exerciseType: exercise.type,
          setIndex: currentSet.value,
          durationSeconds: input.durationSeconds,
          completedAt: now,
        );
      case ExerciseType.running:
        return WorkoutSetResult(
          sessionId: 0,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          exerciseType: exercise.type,
          setIndex: currentSet.value,
          durationSeconds: input.durationSeconds,
          distanceMeters: input.distanceMeters,
          completedAt: now,
        );
    }
  }

  List<String> _validate(WorkoutExercise exercise, WorkoutSetInput input) {
    final probe = ProgramDayExercise(
      dayId: 0,
      orderIndex: 0,
      sets: 1,
      reps: input.reps,
      weightKg: input.weightKg,
      durationSeconds: input.durationSeconds,
      distanceMeters: input.distanceMeters,
    );
    return _validator.validate(probe, exercise.type).errors;
  }

  void _requireInExercise() {
    _requireActive();
    if (phase.value != WorkoutPhase.exercise) {
      throw WorkoutStateException(const ['Подход нельзя подтвердить сейчас']);
    }
  }

  void _requireActive() {
    if (_exercises.isEmpty || currentExercise == null) {
      throw WorkoutStateException(const ['Тренировка не начата']);
    }
  }

  void _cancelTimers() {
    _restTimer?.cancel();
    _restTimer = null;
    _holdTimer?.cancel();
    _holdTimer = null;
  }
}
