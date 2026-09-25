import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/app/widgets/calendar/month_grid.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_thumbnail.dart';
import 'package:fitnessappai/features/programs/ui/program_thumbnail.dart';
import 'package:fitnessappai/features/llm/data/llm_export_service.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/progress/ui/history_controller.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран истории: месячный календарь с подсветкой дней тренировок.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.workoutRepository});

  final WorkoutRepository? workoutRepository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryController _controller;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    ProgramRepository? programRepository;
    try {
      programRepository = locator.get<ProgramRepository>();
    } catch (_) {
      programRepository = null;
    }
    _controller = HistoryController(
      workoutRepository:
          widget.workoutRepository ?? locator.get<WorkoutRepository>(),
      programRepository: programRepository,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  bool get _canGoNextMonth {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    return !_currentMonth.isAtSameMomentAs(current) &&
        _currentMonth.isBefore(current);
  }

  void _nextMonth() {
    if (!_canGoNextMonth) {
      return;
    }
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: Text(l10n.history),
        actions: [
          IconButton(
            tooltip: l10n.historyCopyJsonTooltip,
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () => _copyHistoryJson(context),
          ),
        ],
      ),
      body: SignalBuilder(builder: (_) => _buildBody(context)),
    );
  }

  Future<void> _copyHistoryJson(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final json = await locator.get<LlmExportService>().historyToJson();
    await Clipboard.setData(ClipboardData(text: json));
    messenger.showSnackBar(SnackBar(content: Text(l10n.copyJsonCopied)));
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    final dates = _controller.workoutDates.value;
    if (dates.isEmpty) {
      return Center(
        child: Text(
          l10n.historyEmpty,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
    return Column(
      children: [
        MonthSwitcher(
          label: monthTitle(_currentMonth),
          onPrevious: _previousMonth,
          onNext: _canGoNextMonth ? _nextMonth : null,
        ),
        Expanded(
          child: MonthGridView(
            monthStart: _currentMonth,
            today: DateTime.now(),
            fillHeight: true,
            onPrevious: _previousMonth,
            onNext: _canGoNextMonth ? _nextMonth : null,
            cellBuilder: (context, date) => _buildDayCell(context, date, dates),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime date,
    Set<DateTime> dates,
  ) {
    if (date.month != _currentMonth.month || date.year != _currentMonth.year) {
      return const SizedBox();
    }
    final hasWorkout = dates.contains(date);
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final colorScheme = Theme.of(context).colorScheme;
    return MonthDayCell(
      day: date.day,
      background: hasWorkout
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      foreground: hasWorkout
          ? colorScheme.onPrimaryContainer
          : colorScheme.onSurfaceVariant,
      border: isToday ? Border.all(color: colorScheme.primary) : null,
      isToday: isToday,
      showWorkoutIcon: hasWorkout,
      onTap: hasWorkout ? () => _openDay(context, date) : null,
    );
  }

  void _openDay(BuildContext context, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    context.push(
      '/progress/day?start=${start.millisecondsSinceEpoch}&end=${end.millisecondsSinceEpoch}',
    );
  }
}

/// Экран деталей тренировки: подходы по упражнениям.
class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({
    super.key,
    required this.sessionId,
    this.workoutRepository,
    this.programRepository,
    this.exerciseRepository,
  });

  final int sessionId;
  final WorkoutRepository? workoutRepository;
  final ProgramRepository? programRepository;
  final ExerciseRepository? exerciseRepository;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late final WorkoutRepository _repository;
  ProgramRepository? _programRepository;
  ExerciseRepository? _exerciseRepository;
  MediaCache? _mediaCache;
  final Map<int, Exercise> _exercisesById = {};
  WorkoutSessionDetail? _detail;
  String? _imagePath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.workoutRepository ?? locator.get<WorkoutRepository>();
    try {
      _programRepository =
          widget.programRepository ?? locator.get<ProgramRepository>();
    } catch (_) {
      _programRepository = widget.programRepository;
    }
    try {
      _exerciseRepository =
          widget.exerciseRepository ?? locator.get<ExerciseRepository>();
    } catch (_) {
      _exerciseRepository = widget.exerciseRepository;
    }
    try {
      _mediaCache = locator.get<MediaCache>();
    } catch (_) {
      _mediaCache = null;
    }
    _load();
  }

  Future<void> _load() async {
    final detail = await _repository.getSession(widget.sessionId);
    String? imagePath;
    if (detail != null) {
      final programId = detail.session.programId;
      final repository = _programRepository;
      if (programId != null && repository != null) {
        final program = await repository.getProgram(programId);
        imagePath = program?.program.imagePath;
      }
      final exerciseIds = detail.results
          .map((r) => r.exerciseId)
          .whereType<int>()
          .toSet();
      for (final id in exerciseIds) {
        final exercise = await _exerciseRepository?.getById(id);
        if (exercise != null) {
          _exercisesById[id] = exercise;
        }
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _detail = detail;
      _imagePath = imagePath;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyDetail)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
          ? Center(
              child: Text(
                l10n.historySessionNotFound,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : _buildBody(context, _detail!),
    );
  }

  Widget _buildBody(BuildContext context, WorkoutSessionDetail detail) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = detail.session;
    final date = DateFormat('d MMMM yyyy', 'ru').format(session.performedDate);
    final minutes = session.endedAt.difference(session.startedAt).inMinutes;
    final groups = _groupByExercise(detail.results);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgramThumbnail(imagePath: _imagePath, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.programName, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    [
                      date,
                      if (session.variant == WorkoutVariant.alternative)
                        l10n.programBuilderAlternativeSet,
                      l10n.historyDuration(minutes),
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final entry in groups.entries) ...[
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ExerciseThumbnail(
                        exercise: _exerciseOf(entry.value.first),
                        mediaCache: _mediaCache,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final result in entry.value)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _formatSet(l10n, result),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Map<String, List<WorkoutSetResult>> _groupByExercise(
    List<WorkoutSetResult> results,
  ) {
    final groups = <String, List<WorkoutSetResult>>{};
    for (final result in results) {
      groups.putIfAbsent(result.exerciseName, () => []).add(result);
    }
    return groups;
  }

  Exercise? _exerciseOf(WorkoutSetResult result) {
    final id = result.exerciseId;
    if (id == null) {
      return null;
    }
    return _exercisesById[id];
  }

  String _formatSet(AppLocalizations l10n, WorkoutSetResult result) {
    final index = result.setIndex;
    final sideSuffix = switch (result.side) {
      'left' => 'л',
      'right' => 'п',
      _ => '',
    };
    final label = '$index$sideSuffix.';
    switch (result.exerciseType) {
      case ExerciseType.strength:
        final base = '$label ${result.reps ?? 0} ${l10n.workoutUnitReps}';
        final weight = result.weightKg;
        if (weight != null && weight > 0) {
          return '$base × ${_fmt(weight)} ${l10n.workoutUnitKg}';
        }
        return base;
      case ExerciseType.bodyweight:
        return '$label ${result.reps ?? 0} ${l10n.workoutUnitReps}';
      case ExerciseType.plank:
        return '$label ${result.durationSeconds ?? 0} '
            '${l10n.workoutUnitSeconds}';
      case ExerciseType.running:
        final distance = result.distanceMeters;
        final duration = result.durationSeconds;
        if (distance != null && duration != null) {
          final avgPace = result.avgPace;
          final pacePart = avgPace != null ? ' · ${_fmt(avgPace)} мин/км' : '';
          final steps = result.steps;
          final stepsPart = steps != null
              ? ' · $steps ${l10n.workoutUnitSteps}'
              : '';
          return '$label ${_fmt(distance / 1000)} ${l10n.workoutUnitKm} × '
              '${_fmt(duration / 60)} ${l10n.workoutUnitMinutes}'
              '$pacePart$stepsPart';
        }
        return label;
      case ExerciseType.bike:
        final distance = result.distanceMeters;
        final duration = result.durationSeconds;
        final speed = result.avgSpeed;
        if (distance != null && duration != null) {
          final speedPart = speed != null
              ? ' · ${_fmt(speed)} ${l10n.workoutUnitKmh}'
              : '';
          return '$label ${_fmt(distance / 1000)} ${l10n.workoutUnitKm} × '
              '${_fmt(duration / 60)} ${l10n.workoutUnitMinutes}$speedPart';
        }
        return label;
    }
  }
}

String _fmt(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
