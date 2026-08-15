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

/// Экран списка тренировок: сессии, свежие сверху.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.workoutRepository});

  final WorkoutRepository? workoutRepository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryController _controller;

  @override
  void initState() {
    super.initState();
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
    final items = _controller.items.value;
    if (items.isEmpty) {
      return Center(
        child: Text(
          l10n.historyEmpty,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _HistoryCard(item: items[index]),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = item.session;
    final date = DateFormat('d MMMM yyyy', 'ru').format(session.performedDate);
    final minutes = item.duration.inMinutes;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/history/${session.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.programName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (session.variant == WorkoutVariant.alternative)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        l10n.programBuilderAlternativeSet,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.historyExercisesCount(item.exercisesCount)}'
                ' · ${l10n.historyDuration(minutes)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
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
    switch (result.exerciseType) {
      case ExerciseType.strength:
        final base = '$index. ${result.reps ?? 0} ${l10n.workoutUnitReps}';
        final weight = result.weightKg;
        if (weight != null && weight > 0) {
          return '$base × ${_fmt(weight)} ${l10n.workoutUnitKg}';
        }
        return base;
      case ExerciseType.bodyweight:
        return '$index. ${result.reps ?? 0} ${l10n.workoutUnitReps}';
      case ExerciseType.plank:
        return '$index. ${result.durationSeconds ?? 0} '
            '${l10n.workoutUnitSeconds}';
      case ExerciseType.running:
        final distance = result.distanceMeters;
        final duration = result.durationSeconds;
        if (distance != null && duration != null) {
          return '$index. ${_fmt(distance / 1000)} ${l10n.workoutUnitKm} × '
              '${_fmt(duration / 60)} ${l10n.workoutUnitMinutes}';
        }
        return '$index.';
    }
  }
}

String _fmt(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
