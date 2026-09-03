import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/features/llm/data/llm_export_service.dart';
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
    _controller = HistoryController(
      workoutRepository:
          widget.workoutRepository ?? locator.get<WorkoutRepository>(),
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

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
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
        _MonthSwitcher(
          currentMonth: _currentMonth,
          onPrevious: _previousMonth,
          onNext: _nextMonth,
        ),
        Expanded(
          child: _MonthGrid(
            currentMonth: _currentMonth,
            workoutDates: dates,
            onDayTap: (date) => _openDay(context, date),
          ),
        ),
      ],
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

/// Переключатель месяцев: стрелки + заголовок.
class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.currentMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime currentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat('LLLL yyyy', 'ru').format(currentMonth);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Text(
              monthName,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

/// Сетка месяца: 7 колонок (пн–вс), строки по неделям.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.currentMonth,
    required this.workoutDates,
    required this.onDayTap,
  });

  final DateTime currentMonth;
  final Set<DateTime> workoutDates;
  final void Function(DateTime date) onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = currentMonth.year;
    final month = currentMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    // Понедельник = 0, воскресенье = 6.
    final startWeekday = (firstDay.weekday - 1) % 7;

    final cells = <Widget>[];
    // Заголовки дней недели.
    for (final label in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']) {
      cells.add(
        Center(
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    // Пустые ячейки до первого дня.
    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    // Дни месяца.
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final hasWorkout = workoutDates.contains(date);
      final today = DateTime.now();
      final isToday =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      cells.add(
        GestureDetector(
          onTap: hasWorkout ? () => onDayTap(date) : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: hasWorkout ? theme.colorScheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: hasWorkout
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                fontWeight: hasWorkout ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 1 / 1.2,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}

/// Экран деталей тренировки: подходы по упражнениям.
class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({
    super.key,
    required this.sessionId,
    this.workoutRepository,
  });

  final int sessionId;
  final WorkoutRepository? workoutRepository;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late final WorkoutRepository _repository;
  WorkoutSessionDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.workoutRepository ?? locator.get<WorkoutRepository>();
    _load();
  }

  Future<void> _load() async {
    final detail = await _repository.getSession(widget.sessionId);
    if (!mounted) {
      return;
    }
    setState(() {
      _detail = detail;
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
        const SizedBox(height: 16),
        for (final entry in groups.entries) ...[
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: theme.textTheme.titleSmall),
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
          return '$label ${_fmt(distance / 1000)} ${l10n.workoutUnitKm} × '
              '${_fmt(duration / 60)} ${l10n.workoutUnitMinutes}';
        }
        return label;
    }
  }
}

String _fmt(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
