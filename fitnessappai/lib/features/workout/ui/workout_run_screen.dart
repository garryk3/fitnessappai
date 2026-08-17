import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/domain/workout_controller.dart';
import 'package:fitnessappai/features/workout/domain/workout_exercise.dart';
import 'package:fitnessappai/features/workout/domain/workout_set_input.dart';
import 'package:fitnessappai/features/workout/ui/workout_run_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Удержание экрана включённым во время тренировки.
abstract class WakelockService {
  Future<void> enable();

  Future<void> disable();
}

/// Реализация через плагин wakelock_plus.
class WakelockPlusService implements WakelockService {
  const WakelockPlusService();

  @override
  Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      log('Не удалось включить wakelock', error: e);
    }
  }

  @override
  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      log('Не удалось выключить wakelock', error: e);
    }
  }
}

/// Экран выполнения тренировки: подходы, отдых и сохранение результатов.
class WorkoutRunScreen extends StatefulWidget {
  const WorkoutRunScreen({
    super.key,
    required this.programDayId,
    required this.variant,
    this.programRepository,
    this.exerciseRepository,
    this.workoutRepository,
    this.mediaCache,
    this.wakelockService = const WakelockPlusService(),
    this.clock,
    this.timerFactory,
    this.soundService,
  });

  final int programDayId;
  final WorkoutVariant variant;
  final ProgramRepository? programRepository;
  final ExerciseRepository? exerciseRepository;
  final WorkoutRepository? workoutRepository;
  final MediaCache? mediaCache;
  final WakelockService wakelockService;
  final DateTime Function()? clock;
  final TimerFactory? timerFactory;
  final SoundService? soundService;

  @override
  State<WorkoutRunScreen> createState() => _WorkoutRunScreenState();
}

class _WorkoutRunScreenState extends State<WorkoutRunScreen> {
  late final WorkoutRunController _controller;
  late final MediaCache _mediaCache;
  late final WorkoutRepository _workoutRepository;

  @override
  void initState() {
    super.initState();
    _mediaCache = widget.mediaCache ?? locator.get<MediaCache>();
    _workoutRepository =
        widget.workoutRepository ?? locator.get<WorkoutRepository>();
    _controller = WorkoutRunController(
      programDayId: widget.programDayId,
      variant: widget.variant,
      programRepository:
          widget.programRepository ?? locator.get<ProgramRepository>(),
      exerciseRepository:
          widget.exerciseRepository ?? locator.get<ExerciseRepository>(),
      workoutRepository:
          widget.workoutRepository ?? locator.get<WorkoutRepository>(),
      soundService: widget.soundService ?? locator.get<SoundService>(),
      clock: widget.clock,
      timerFactory: widget.timerFactory,
    );
    widget.wakelockService.enable();
  }

  @override
  void dispose() {
    _controller.workout.dispose();
    widget.wakelockService.disable();
    super.dispose();
  }

  Future<void> _handlePopRequest() async {
    if (_controller.saved.value) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    final l10n = AppLocalizations.of(context);
    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workoutRunExitTitle),
        content: Text(l10n.workoutRunExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.workoutRunExit),
          ),
        ],
      ),
    );
    if (exit != true || !mounted) {
      return;
    }
    _controller.workout.cancelWorkout();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handlePopRequest();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).workoutRun)),
        body: SignalBuilder(builder: (_) => _buildBody(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller;
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.notFound.value) {
      return Center(child: Text(l10n.workoutPrepareNotFound));
    }
    if (controller.emptyDay.value) {
      return Center(child: Text(l10n.workoutRunEmpty));
    }
    final workout = controller.workout;
    switch (workout.phase.value) {
      case WorkoutPhase.exercise:
        return _buildExercise(context, workout);
      case WorkoutPhase.rest:
        return _buildRest(context, workout);
      case WorkoutPhase.finished:
        return _FinishedView(
          controller: controller,
          saving: controller.saving.value,
          saved: controller.saved.value,
        );
      case WorkoutPhase.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildExercise(BuildContext context, WorkoutController workout) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final exercise = workout.currentExercise!;
    final index = workout.currentExerciseIndex.value;
    final total = workout.exercises.length;
    final currentSet = workout.currentSet.value;
    final totalSets = _controller.totalSets;
    final completed = workout.completedSets.value;
    final holdElapsed = workout.holdElapsedSeconds.value;
    final holdTarget = workout.holdTargetSeconds.value;
    final holdRunning = workout.holdRunning.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: totalSets == 0 ? 0 : completed / totalSets,
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.workoutRunExerciseOf(index + 1, total)}'
            ' · ${l10n.workoutRunSetOf(currentSet, exercise.sets)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _ExerciseMedia(exercise: exercise.exercise, mediaCache: _mediaCache),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  exercise.name,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              if (exercise.id != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.exerciseDetail,
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => context.push('/exercises/${exercise.id}'),
                ),
              ],
            ],
          ),
          if (exercise.type == ExerciseType.plank && holdTarget != null) ...[
            const SizedBox(height: 12),
            _PlankHoldPanel(
              elapsed: holdElapsed,
              target: holdTarget,
              running: holdRunning,
              onStart: workout.startHoldTimer,
            ),
          ],
          if (exercise.id != null) ...[
            const SizedBox(height: 12),
            _LastWorkoutCard(
              exercise: exercise,
              repository: _workoutRepository,
            ),
          ],
          const SizedBox(height: 16),
          _ExerciseInputForm(
            key: ValueKey('input-$index-$currentSet'),
            exercise: exercise,
            onConfirm: _controller.confirmSet,
            holdElapsed: () => workout.holdElapsedSeconds.value,
          ),
        ],
      ),
    );
  }

  Widget _buildRest(BuildContext context, WorkoutController workout) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final remaining = workout.restRemainingSeconds.value ?? 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.workoutRunRest, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(
            '$remaining',
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: workout.skipRest,
            child: Text(l10n.workoutRunSkipRest),
          ),
        ],
      ),
    );
  }
}

/// Анимация упражнения с плейсхолдером при отсутствии файла.
class _ExerciseMedia extends StatelessWidget {
  const _ExerciseMedia({required this.exercise, required this.mediaCache});

  final Exercise exercise;
  final MediaCache mediaCache;

  @override
  Widget build(BuildContext context) {
    final path = exercise.animationPath ?? exercise.thumbnailPath;
    if (path == null) {
      return _mediaPlaceholder(context);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image(
        image: mediaCache.imageFor(path),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _mediaPlaceholder(context),
      ),
    );
  }

  Widget _mediaPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        switch (exercise.type) {
          ExerciseType.strength => Icons.fitness_center,
          ExerciseType.bodyweight => Icons.accessibility_new,
          ExerciseType.plank => Icons.self_improvement,
          ExerciseType.running => Icons.directions_run,
        },
        size: 56,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Результаты текущего упражнения из последней тренировки.
///
/// Пустая карточка не отображается, если упражнение ещё не выполнялось.
class _LastWorkoutCard extends StatefulWidget {
  const _LastWorkoutCard({required this.exercise, required this.repository});

  final WorkoutExercise exercise;
  final WorkoutRepository repository;

  @override
  State<_LastWorkoutCard> createState() => _LastWorkoutCardState();
}

class _LastWorkoutCardState extends State<_LastWorkoutCard> {
  late final Future<List<WorkoutSetResult>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.lastResultsForExercise(widget.exercise.id!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return FutureBuilder<List<WorkoutSetResult>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final results = snapshot.data;
        if (results == null || results.isEmpty) {
          return const SizedBox.shrink();
        }
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.workoutRunLastWorkout,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                for (final result in results)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      '${result.setIndex}. '
                      '${_formatResult(l10n, result)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatResult(AppLocalizations l10n, WorkoutSetResult result) {
    return switch (result.exerciseType) {
      ExerciseType.strength when result.weightKg != null =>
        '${result.reps ?? 0} × ${_fmt(result.weightKg!)} ${l10n.workoutUnitKg}',
      ExerciseType.strength ||
      ExerciseType.bodyweight => '${result.reps ?? 0} ${l10n.workoutUnitReps}',
      ExerciseType.plank =>
        '${result.durationSeconds ?? 0} ${l10n.workoutUnitSeconds}',
      ExerciseType.running =>
        '${_fmt((result.distanceMeters ?? 0) / 1000)} ${l10n.workoutUnitKm} × '
            '${(result.durationSeconds ?? 0) ~/ 60} ${l10n.workoutUnitMinutes}',
    };
  }
}

String _fmt(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

/// Выделенный блок таймера удержания планки: крупный счётчик, цель в скобках,
/// кнопка запуска до старта.
class _PlankHoldPanel extends StatelessWidget {
  const _PlankHoldPanel({
    required this.elapsed,
    required this.target,
    required this.running,
    required this.onStart,
  });

  final int elapsed;
  final int target;
  final bool running;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reached = running && elapsed >= target;
    final counterColor = reached
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: reached
            ? theme.colorScheme.tertiaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            l10n.workoutRunHold(elapsed),
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: counterColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.workoutRunHoldTarget(target),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (!running) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.workoutRunHoldStart),
            ),
          ],
        ],
      ),
    );
  }
}

/// Форма ввода результатов подхода. Создаётся заново для каждого подхода.
class _ExerciseInputForm extends StatefulWidget {
  const _ExerciseInputForm({
    super.key,
    required this.exercise,
    required this.onConfirm,
    this.holdElapsed,
  });

  final WorkoutExercise exercise;
  final void Function(WorkoutSetInput input) onConfirm;

  /// Фактическое время удержания планки. Для планки пустое поле времени
  /// заменяется текущим значением счётчика.
  final int Function()? holdElapsed;

  @override
  State<_ExerciseInputForm> createState() => _ExerciseInputFormState();
}

class _ExerciseInputFormState extends State<_ExerciseInputForm> {
  final _formKey = GlobalKey<FormState>();
  late final _reps = TextEditingController();
  late final _weight = TextEditingController();
  late final _duration = TextEditingController();
  late final _distance = TextEditingController();

  @override
  void dispose() {
    _reps.dispose();
    _weight.dispose();
    _duration.dispose();
    _distance.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final input = switch (widget.exercise.type) {
      ExerciseType.strength => WorkoutSetInput(
        reps: int.parse(_reps.text.trim()),
        weightKg: _parseDouble(_weight.text),
      ),
      ExerciseType.bodyweight => WorkoutSetInput(
        reps: int.parse(_reps.text.trim()),
      ),
      ExerciseType.plank => WorkoutSetInput(
        durationSeconds: _parsePlankDuration(),
      ),
      ExerciseType.running => _buildRunningInput(),
    };
    widget.onConfirm(input);
  }

  /// Время планки: ручной ввод, либо текущее значение счётчика удержания.
  int _parsePlankDuration() {
    final manual = int.tryParse(_duration.text.trim());
    return manual ?? (widget.holdElapsed?.call() ?? 0);
  }

  WorkoutSetInput _buildRunningInput() {
    final distanceKm = _parseDouble(_distance.text);
    final minutes = int.tryParse(_minutes.text.trim());
    if (distanceKm == null || minutes == null) {
      throw StateError('Валидатор пропустил пустую дистанцию/время бега');
    }
    return WorkoutSetInput(
      durationSeconds: minutes * 60,
      distanceMeters: distanceKm * 1000,
    );
  }

  double? _parseDouble(String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    return parsed;
  }

  TextEditingController get _minutes => _duration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...switch (widget.exercise.type) {
            ExerciseType.strength => [
              TextFormField(
                controller: _reps,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.exerciseParamsReps,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final reps = int.tryParse(value?.trim() ?? '');
                  if (reps == null) {
                    return l10n.exerciseParamsRequired;
                  }
                  if (reps < 1) {
                    return l10n.exerciseParamsPositive;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [DoubleTextInputFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.exerciseParamsWeightKg,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final weight = _parseDouble(value ?? '');
                  if (weight != null && weight < 0) {
                    return l10n.exerciseParamsNotNegative;
                  }
                  return null;
                },
              ),
            ],
            ExerciseType.bodyweight => [
              TextFormField(
                controller: _reps,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.exerciseParamsReps,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final reps = int.tryParse(value?.trim() ?? '');
                  if (reps == null) {
                    return l10n.exerciseParamsRequired;
                  }
                  if (reps < 1) {
                    return l10n.exerciseParamsPositive;
                  }
                  return null;
                },
              ),
            ],
            ExerciseType.plank => [
              TextFormField(
                controller: _duration,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.exerciseParamsDurationSeconds,
                  helperText: l10n.exerciseParamsHoldHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final seconds = int.tryParse(value?.trim() ?? '');
                  if (seconds == null) {
                    // Пустое поле — в результат пойдёт время удержания
                    // со счётчика (задача 13.5).
                    return null;
                  }
                  if (seconds < 1) {
                    return l10n.exerciseParamsPositive;
                  }
                  return null;
                },
              ),
            ],
            ExerciseType.running => [
              TextFormField(
                controller: _distance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [DoubleTextInputFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.exerciseParamsDistanceKm,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final km = _parseDouble(value ?? '');
                  if (km == null) {
                    return l10n.exerciseParamsRequired;
                  }
                  if (km < 0) {
                    return l10n.exerciseParamsNotNegative;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _duration,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.exerciseParamsDurationMinutes,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final minutes = int.tryParse(value?.trim() ?? '');
                  if (minutes == null) {
                    return l10n.exerciseParamsRequired;
                  }
                  if (minutes < 1) {
                    return l10n.exerciseParamsPositive;
                  }
                  return null;
                },
              ),
            ],
          },
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: Text(l10n.workoutRunApproachDone),
          ),
        ],
      ),
    );
  }
}

/// Экран итогов завершённой тренировки.
class _FinishedView extends StatelessWidget {
  const _FinishedView({
    required this.controller,
    required this.saving,
    required this.saved,
  });

  final WorkoutRunController controller;
  final bool saving;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final workout = controller.workout;
    final programName = workout.context?.programName ?? '';
    final setsCount = workout.results.value.length;
    final minutes = controller.durationMinutes;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.workoutRunFinished,
              style: theme.textTheme.headlineMedium,
            ),
            if (programName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(programName, style: theme.textTheme.titleMedium),
            ],
            const SizedBox(height: 16),
            Text(l10n.workoutRunSetsCount(setsCount)),
            Text(l10n.workoutRunTime(minutes)),
            const SizedBox(height: 24),
            if (saved) ...[
              Text(
                l10n.workoutRunSaved,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/progress'),
                child: Text(l10n.workoutRunGoProgress),
              ),
            ] else
              FilledButton(
                onPressed: saving ? null : controller.completeAndSave,
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.workoutRunFinish),
              ),
          ],
        ),
      ),
    );
  }
}

/// Разрешает ввод дробного числа (запятая или точка как разделитель).
class DoubleTextInputFormatter extends TextInputFormatter {
  static final _regExp = RegExp(r'^\d*[,.]?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _regExp.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
