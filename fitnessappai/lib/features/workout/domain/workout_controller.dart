import 'dart:async';
import 'dart:convert';

import 'package:signals/signals.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/domain/validators/program_day_exercise_validator.dart';
import 'package:fitnessappai/features/workout/domain/workout_checkpoint.dart';
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

  /// Текущая сторона для упражнения «по сторонам»: null — упражнение обычное
  /// или обе стороны выполнены; 'right' — правая сторона ещё не выполнена.
  final Signal<String?> currentSide = Signal(null);

  /// Остаток отдыха между сторонами (null — отдых не идёт).
  final Signal<int?> sideRest = Signal(null);

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
  DateTime? _restEndsAt;
  Timer? _restTimer;
  Timer? _holdTimer;

  /// Поколение сессии: инкрементируется при каждом `start`/`restore`.
  /// Таймеры, созданные в прошлом поколении, при срабатывании становятся
  /// no-op (защита от stale-таймера после перезапуска/восстановления).
  int _generation = 0;

  /// Идёт ли пауза отдыха между упражнениями (перед переходом к следующему).
  bool _restBetweenExercises = false;

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
    _generation++;
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
    currentSide.value = null;
    sideRest.value = null;
    _restBetweenExercises = false;
    _prepareHoldTimer();
  }

  /// Сохраняет текущий state в чекпоинт для восстановления после убийства ОС.
  WorkoutCheckpoint toCheckpoint({
    required int programDayId,
    int? programId,
    required String programName,
    required int dayIndex,
  }) {
    return WorkoutCheckpoint(
      programDayId: programDayId,
      exerciseIndex: currentExerciseIndex.value,
      currentSet: currentSet.value,
      completedSets: completedSets.value,
      resultsJson: jsonEncode([
        for (final r in results.value)
          {
            'exerciseId': r.exerciseId,
            'exerciseName': r.exerciseName,
            'exerciseType': r.exerciseType.name,
            'setIndex': r.setIndex,
            'reps': r.reps,
            'weightKg': r.weightKg,
            'durationSeconds': r.durationSeconds,
            'distanceMeters': r.distanceMeters,
            'completedAt': r.completedAt.toIso8601String(),
          },
      ]),
      startedAt: _startedAt ?? _clock(),
      programId: programId,
      programName: programName,
      dayIndex: dayIndex,
      currentSide: currentSide.value,
      phase: phase.value.name,
      restEndsAt: _restEndsAt,
      restBetweenExercises: _restBetweenExercises,
      sideRest: sideRest.value != null,
      holdElapsedSeconds: holdElapsedSeconds.value,
      holdTargetSeconds: holdTargetSeconds.value,
      holdRunning: holdRunning.value,
    );
  }

  /// Восстанавливает state из чекпоинта.
  void restoreFromCheckpoint(
    WorkoutCheckpoint checkpoint,
    List<WorkoutExercise> exercises,
  ) {
    _generation++;
    _cancelTimers();
    _exercises
      ..clear()
      ..addAll(exercises);
    _startedAt = checkpoint.startedAt;
    final safeIndex = checkpoint.exerciseIndex.clamp(
      0,
      exercises.isEmpty ? 0 : exercises.length - 1,
    );
    currentExerciseIndex.value = safeIndex;
    currentSet.value = checkpoint.currentSet;
    completedSets.value = checkpoint.completedSets;
    currentSide.value = checkpoint.currentSide;
    restRemainingSeconds.value = null;
    sideRest.value = null;
    _restBetweenExercises = checkpoint.restBetweenExercises;
    final decoded = jsonDecode(checkpoint.resultsJson) as List;
    results.value = [
      for (final item in decoded)
        WorkoutSetResult(
          sessionId: 0,
          exerciseId: item['exerciseId'] as int,
          exerciseName: item['exerciseName'] as String,
          exerciseType: ExerciseType.values.firstWhere(
            (e) => e.name == item['exerciseType'],
          ),
          setIndex: item['setIndex'] as int,
          reps: item['reps'] as int?,
          weightKg: (item['weightKg'] as num?)?.toDouble(),
          durationSeconds: item['durationSeconds'] as int?,
          distanceMeters: (item['distanceMeters'] as num?)?.toDouble(),
          completedAt: DateTime.parse(item['completedAt'] as String),
        ),
    ];
    if (checkpoint.phase == 'rest' && checkpoint.restEndsAt != null) {
      _resumeRest(
        checkpoint.restEndsAt!,
        between: checkpoint.restBetweenExercises,
        side: checkpoint.sideRest,
      );
    } else {
      phase.value = WorkoutPhase.exercise;
      _restoreHold(checkpoint);
    }
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
    _soundService?.stop();
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

    final side = _currentSideFor(exercise);
    results.value = [
      ...results.value,
      _buildResult(exercise, input.copyWith(side: side), _clock()),
    ];

    if (side == 'left') {
      // Левая сторона выполнена: отдых между сторонами, затем правая.
      currentSide.value = 'right';
      _startRest(exercise.restSeconds, side: true);
      return;
    }

    completedSets.value++;
    currentSide.value = null;

    if (currentSet.value < exercise.sets) {
      currentSet.value++;
      _startRest(exercise.restSeconds);
    } else if (!isLastExercise) {
      // Все подходы упражнения выполнены: перед следующим упражнением —
      // пауза отдыха, если она задана на программе.
      final betweenRest = _context?.exerciseRestSeconds ?? 0;
      if (betweenRest > 0) {
        _restBetweenExercises = true;
        _startRestBetween(betweenRest);
        return;
      }
      _advanceToNextExercise();
    } else {
      phase.value = WorkoutPhase.finished;
    }
  }

  /// Сторона текущего подхода: для упражнений «по сторонам» — первая
  /// (левая) или уже назначенная [currentSide]; для остальных — null.
  String? _currentSideFor(WorkoutExercise exercise) {
    if (!exercise.exercise.perSide) {
      return null;
    }
    return currentSide.value ?? 'left';
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
    _soundService?.stop();
    _restTimer?.cancel();
    _restTimer = null;
    _restEndsAt = null;
    restRemainingSeconds.value = null;
    sideRest.value = null;
    if (_restBetweenExercises) {
      _restBetweenExercises = false;
      _advanceToNextExercise();
      return;
    }
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
    _restEndsAt = null;
    restRemainingSeconds.value = null;
    sideRest.value = null;
    currentSide.value = null;
    _restBetweenExercises = false;
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
    _soundService?.stop();
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

  /// Досрочно завершает тренировку (из фазы exercise/rest), позволяя сохранить
  /// частичные результаты. Переходит в [WorkoutPhase.finished], после чего
  /// [completeWorkout] работает штатно (задача 14.9).
  void finishEarly() {
    if (phase.value != WorkoutPhase.exercise &&
        phase.value != WorkoutPhase.rest) {
      throw WorkoutStateException(const ['Тренировка не в процессе']);
    }
    _soundService?.stop();
    _cancelTimers();
    phase.value = WorkoutPhase.finished;
  }

  /// Отменяет тренировку, ничего не сохраняя. Сбрасывает состояние.
  void cancelWorkout() {
    _soundService?.stop();
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
    currentSide.value = null;
    sideRest.value = null;
    _restBetweenExercises = false;
    holdRunning.value = false;
    holdElapsedSeconds.value = 0;
    holdTargetSeconds.value = null;
  }

  /// Останавливает воспроизведение звука.
  void stopSound() {
    _soundService?.stop();
  }

  void dispose() {
    _cancelTimers();
  }

  void _startRest(int restSeconds, {bool side = false}) {
    if (restSeconds <= 0) {
      phase.value = WorkoutPhase.exercise;
      _prepareHoldTimer();
      return;
    }
    phase.value = WorkoutPhase.rest;
    final remainingSignal = side ? sideRest : restRemainingSeconds;
    // Отсчёт ведётся от времени окончания по wall-clock: при уходе в сон и
    // возврате первый тик корректно завершает отдых, а не продолжает счёт
    // с прежнего значения (задача 14.8).
    _restEndsAt = _clock().add(Duration(seconds: restSeconds));
    remainingSignal.value = restSeconds;
    _restTimer?.cancel();
    _restTimer = _makeRestTicker(remainingSignal, _completeNormalRest);
  }

  /// Начинает паузу отдыха между упражнениями. По завершении переходит
  /// к следующему упражнению.
  void _startRestBetween(int restSeconds) {
    phase.value = WorkoutPhase.rest;
    _restEndsAt = _clock().add(Duration(seconds: restSeconds));
    restRemainingSeconds.value = restSeconds;
    _restTimer?.cancel();
    _restTimer = _makeRestTicker(restRemainingSeconds, _completeBetweenRest);
  }

  /// Возобновляет отдых из чекпоинта. [restEndsAt] — сохранённое время
  /// окончания по wall-clock; если отдых уже истёк во время «сна», завершает
  /// его немедленно.
  void _resumeRest(
    DateTime restEndsAt, {
    required bool between,
    required bool side,
  }) {
    final remaining = restEndsAt.difference(_clock()).inSeconds;
    if (remaining <= 0) {
      _restEndsAt = null;
      _restTimer = null;
      restRemainingSeconds.value = null;
      sideRest.value = null;
      if (between) {
        _restBetweenExercises = false;
        _advanceToNextExercise();
      } else {
        phase.value = WorkoutPhase.exercise;
        _prepareHoldTimer();
      }
      return;
    }
    _restEndsAt = restEndsAt;
    phase.value = WorkoutPhase.rest;
    final remainingSignal = side ? sideRest : restRemainingSeconds;
    remainingSignal.value = remaining;
    _restTimer = _makeRestTicker(
      remainingSignal,
      between ? _completeBetweenRest : _completeNormalRest,
    );
  }

  /// Создаёт тикер отдыха: пересчитывает остаток от [_restEndsAt] и по
  /// достижении нуля вызывает [onComplete].
  Timer _makeRestTicker(
    Signal<int?> remainingSignal,
    void Function() onComplete,
  ) {
    final generation = _generation;
    return _timerFactory(const Duration(seconds: 1), (timer) {
      if (generation != _generation) {
        timer.cancel();
        return;
      }
      final endsAt = _restEndsAt;
      if (endsAt == null) {
        timer.cancel();
        return;
      }
      final remaining = endsAt.difference(_clock()).inSeconds;
      if (remaining <= 0) {
        timer.cancel();
        _restTimer = null;
        _restEndsAt = null;
        remainingSignal.value = null;
        onComplete();
      } else {
        remainingSignal.value = remaining;
      }
    });
  }

  /// Завершение обычного отдыха (между подходами или между сторонами).
  void _completeNormalRest() {
    phase.value = WorkoutPhase.exercise;
    _prepareHoldTimer();
    _soundService?.playCompletion();
  }

  /// Завершение отдыха между упражнениями: переход к следующему упражнению.
  void _completeBetweenRest() {
    _restBetweenExercises = false;
    _advanceToNextExercise();
    _soundService?.playCompletion();
  }

  /// Восстанавливает удержание планки из чекпоинта. [holdTargetSeconds]
  /// пересчитывается из текущего упражнения; фактическое время и признак
  /// запуска — из снимка.
  void _restoreHold(WorkoutCheckpoint checkpoint) {
    _prepareHoldTimer();
    if (!checkpoint.holdRunning) {
      return;
    }
    holdElapsedSeconds.value = checkpoint.holdElapsedSeconds;
    holdRunning.value = true;
    final startedAt = _clock().subtract(
      Duration(seconds: checkpoint.holdElapsedSeconds),
    );
    final generation = _generation;
    _holdTimer?.cancel();
    _holdTimer = _timerFactory(const Duration(seconds: 1), (timer) {
      if (generation != _generation) {
        timer.cancel();
        return;
      }
      holdElapsedSeconds.value = _clock().difference(startedAt).inSeconds;
    });
  }

  /// Переходит к следующему упражнению после паузы между упражнениями.
  void _advanceToNextExercise() {
    currentExerciseIndex.value++;
    currentSet.value = 1;
    phase.value = WorkoutPhase.exercise;
    _prepareHoldTimer();
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
  /// попало в результат. Время берётся по wall-clock, поэтому при уходе в
  /// сон и возврате счётчик не замирает.
  void startHoldTimer() {
    if (phase.value != WorkoutPhase.exercise ||
        holdTargetSeconds.value == null ||
        holdRunning.value) {
      return;
    }
    holdElapsedSeconds.value = 0;
    holdRunning.value = true;
    final startedAt = _clock();
    final generation = _generation;
    _holdTimer?.cancel();
    _holdTimer = _timerFactory(const Duration(seconds: 1), (timer) {
      if (generation != _generation) {
        timer.cancel();
        return;
      }
      holdElapsedSeconds.value = _clock().difference(startedAt).inSeconds;
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
          side: input.side,
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
          side: input.side,
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
          side: input.side,
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
          side: input.side,
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
    _restEndsAt = null;
    _holdTimer?.cancel();
    _holdTimer = null;
  }
}
