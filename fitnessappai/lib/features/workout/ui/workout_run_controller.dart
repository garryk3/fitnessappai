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

  /// Незавершённое сохранение сессии (см. [completeAndSave]).
  ///
  /// Гонка до фикса (задача 53.5): тап «Завершить и сохранить» в диалоге
  /// выводил фазу в `finished`, после чего `_FinishedView.initState` дёргал
  /// `completeAndSave()` повторно, пока первое сохранение ещё летело в БД
  /// (`saved.value` выставляется только после `await`) — сессия писалась
  /// дважды. Теперь параллельные вызовы разделяют один и тот же future.
  Future<void>? _saveInFlight;

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
    final context = WorkoutSessionContext(
      programName: exercise.name,
      dayIndex: 0,
    );
    if (checkpoint != null) {
      workout.restoreFromCheckpoint(checkpoint, exercises, context: context);
    } else {
      workout.start(exercises, context: context);
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
    final context = WorkoutSessionContext(
      programId: program?.id,
      programName: program?.name ?? '',
      programDayId: day.id,
      dayIndex: day.dayIndex,
      variant: variant,
      exerciseRestSeconds: program?.exerciseRestSeconds,
    );
    if (checkpoint != null) {
      workout.restoreFromCheckpoint(checkpoint, exercises, context: context);
    } else {
      workout.start(exercises, context: context);
    }
  }

  /// Фиксирует введённые значения подхода.
  void confirmSet(WorkoutSetInput input) {
    workout.setResult(input);
    workout.confirmSet();
  }

  /// Завершает тренировку и сохраняет сессию с результатами.
  ///
  /// Идемпотентно относительно повторных/параллельных вызовов (см.
  /// [_saveInFlight]): повторный вызов возвращает тот же future.
  Future<void> completeAndSave() {
    if (workout.phase.value != WorkoutPhase.finished) {
      return Future.value();
    }
    if (saved.value) {
      return Future.value();
    }
    // Сброс мемоизации через whenComplete: callback отложится в микротаск уже
    // после присваивания `_saveInFlight`, поэтому даже синхронный провал
    // `_save()` не оставит залипший stale-future — после неудачи повторный
    // вызов начнёт новую попытку.
    return _saveInFlight ??= _save().whenComplete(() => _saveInFlight = null);
  }

  Future<void> _save() async {
    saving.value = true;
    try {
      final result = workout.completeWorkout();
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

  /// Перезапускает ту же тренировку после завершения («Повторить тренировку»,
  /// 54.6) — без навигации.
  ///
  /// Навигация `pushReplacement` на тот же путь ненадёжна: go_router при
  /// единственном маршруте в стеке возвращает декларативный список с тем же
  /// `pageKey`, Navigator переиспользует Element и старый State с фазой
  /// `finished` остаётся на экране. Перезапуск на месте сбрасывает флаги
  /// сохранения и прогоняет [load] заново: `workout.start` очищает результаты
  /// и возвращает фазу `exercise`.
  Future<void> restart() async {
    _saveInFlight = null;
    _savedDetail = null;
    saved.value = false;
    saving.value = false;
    await load();
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
