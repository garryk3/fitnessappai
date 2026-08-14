import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/progress/ui/history_controller.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран деталей дня из прогресса: сессии в диапазоне `[start, end)`.
///
/// В недельном периоде срез — один день, в месячном — неделя,
/// в годовом — месяц.
class DayDetailScreen extends StatefulWidget {
  const DayDetailScreen({
    super.key,
    required this.start,
    required this.end,
    this.workoutRepository,
  });

  final DateTime start;
  final DateTime end;
  final WorkoutRepository? workoutRepository;

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late final WorkoutRepository _repository;
  List<HistoryItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.workoutRepository ?? locator.get<WorkoutRepository>();
    _load();
  }

  Future<void> _load() async {
    final sessions = await _repository.getSessionsBetween(
      widget.start,
      widget.end,
    );
    final result = <HistoryItem>[];
    for (final session in sessions) {
      final detail = await _repository.getSession(session.id!);
      final count = detail == null
          ? 0
          : detail.results.map((r) => r.exerciseName).toSet().length;
      result.add(HistoryItem(session: session, exercisesCount: count));
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _items = result;
      _loading = false;
    });
  }

  String get _title {
    final format = DateFormat('d MMMM yyyy', 'ru');
    if (widget.end.isAfter(widget.start.add(const Duration(days: 1)))) {
      return '${format.format(widget.start)} — ${format.format(widget.end.subtract(const Duration(days: 1)))}';
    }
    return format.format(widget.start);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
              child: Text(
                l10n.progressDayEmpty,
                style: theme.textTheme.titleMedium,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _SessionCard(item: _items[index]),
            ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.item});

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
          padding: const EdgeInsets.all(12),
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
