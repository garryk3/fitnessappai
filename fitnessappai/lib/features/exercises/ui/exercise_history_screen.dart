import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/workout_set_result.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Подпись подхода с учётом стороны: «1л.», «2п.», «3.».
String sideLabel(int setIndex, String? side) {
  final suffix = switch (side) {
    'left' => 'л',
    'right' => 'п',
    _ => '',
  };
  return '$setIndex$suffix.';
}

/// Читаемая строка результата подхода по типу упражнения:
/// «8 × 20 кг», «15 повт», «60 с», «5 км × 30 мин».
String formatSetResult(AppLocalizations l10n, WorkoutSetResult result) {
  return switch (result.exerciseType) {
    ExerciseType.strength when result.weightKg != null =>
      '${result.reps ?? 0} × ${_fmt(result.weightKg!)} ${l10n.workoutUnitKg}',
    ExerciseType.strength ||
    ExerciseType.bodyweight => '${result.reps ?? 0} ${l10n.workoutUnitReps}',
    ExerciseType.plank =>
      '${result.durationSeconds ?? 0} ${l10n.workoutUnitSeconds}',
    ExerciseType.distance =>
      '${_fmt((result.distanceMeters ?? 0) / 1000)} ${l10n.workoutUnitKm} × '
          '${(result.durationSeconds ?? 0) ~/ 60} ${l10n.workoutUnitMinutes}',
  };
}

String _fmt(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

/// Экран истории выполнения упражнения (59.3): все сессии, где упражнение
/// выполнялось, от новых к старым; внутри сессии — подходы по порядку.
class ExerciseHistoryScreen extends StatefulWidget {
  const ExerciseHistoryScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    this.workoutRepository,
  });

  final int exerciseId;

  /// Имя упражнения для подзаголовка appBar.
  final String exerciseName;
  final WorkoutRepository? workoutRepository;

  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  late final Future<List<WorkoutSessionDetail>> _future;

  @override
  void initState() {
    super.initState();
    final repository =
        widget.workoutRepository ?? locator.get<WorkoutRepository>();
    _future = repository.resultsHistoryForExercise(widget.exerciseId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      appBar: AppTopBar(title: l10n.exerciseHistoryTitle),
      body: FutureBuilder<List<WorkoutSessionDetail>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.history_outlined,
              title: l10n.exerciseHistoryTitle,
              hint: l10n.progressDayEmptyHint,
            );
          }
          final entries = snapshot.data;
          if (entries == null) {
            return const Center(child: AppSpinner());
          }
          if (entries.isEmpty) {
            return AppEmptyState(
              icon: Icons.history_outlined,
              title: l10n.exerciseHistoryEmpty,
              hint: widget.exerciseName,
            );
          }
          final theme = Theme.of(context);
          final dateFormat = DateFormat('d MMMM yyyy', 'ru');
          return AppListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      dateFormat.format(entry.session.performedDate),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    for (final result in entry.results)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: AppText(
                          '${sideLabel(result.setIndex, result.side)} '
                          '${formatSetResult(l10n, result)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
