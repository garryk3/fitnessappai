import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program_day_exercise.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/ui/workout_prepare_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран подготовки к тренировке: список упражнений дня и выбор набора.
class WorkoutPrepareScreen extends StatefulWidget {
  const WorkoutPrepareScreen({
    super.key,
    required this.programDayId,
    this.programRepository,
    this.exerciseRepository,
    this.profileRepository,
  });

  final int programDayId;
  final ProgramRepository? programRepository;
  final ExerciseRepository? exerciseRepository;
  final UserProfileRepository? profileRepository;

  @override
  State<WorkoutPrepareScreen> createState() => _WorkoutPrepareScreenState();
}

class _WorkoutPrepareScreenState extends State<WorkoutPrepareScreen> {
  late final WorkoutPrepareController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WorkoutPrepareController(
      programDayId: widget.programDayId,
      programRepository:
          widget.programRepository ?? locator.get<ProgramRepository>(),
      exerciseRepository:
          widget.exerciseRepository ?? locator.get<ExerciseRepository>(),
      profileRepository:
          widget.profileRepository ?? locator.get<UserProfileRepository>(),
    );
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    final warnings = _controller.visibleWarnings;
    if (warnings.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.workoutWarningsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.workoutWarningsBody),
              const SizedBox(height: 8),
              for (final warning in warnings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${warning.exerciseName} — '
                    '${warning.tagLabels.join(', ')}',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.workoutWarningsProceed),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) {
        return;
      }
    }
    context.push(
      '/workout/run?programDayId=${widget.programDayId}'
      '&variant=${_controller.variant.value.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutPrepare)),
      body: SignalBuilder(builder: (context) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = _controller;
    final l10n = AppLocalizations.of(context);
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.notFound.value) {
      return Center(child: Text(l10n.workoutPrepareNotFound));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.programName.value,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.programBuilderDay(controller.dayIndex.value + 1),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (controller.hasAlternative)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<WorkoutVariant>(
              segments: [
                ButtonSegment(
                  value: WorkoutVariant.main,
                  label: Text(l10n.programBuilderMainSet),
                ),
                ButtonSegment(
                  value: WorkoutVariant.alternative,
                  label: Text(l10n.programBuilderAlternativeSet),
                ),
              ],
              selected: {controller.variant.value},
              onSelectionChanged: (selection) =>
                  controller.variant.value = selection.first,
            ),
          ),
        Expanded(
          child: controller.visibleItems.isEmpty
              ? Center(
                  child: Text(
                    l10n.programBuilderEmptyDay,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.visibleItems.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ExerciseCard(item: controller.visibleItems[index]),
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.workoutPrepareStart),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.item});

  final WorkoutPrepareItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final exercise = item.exercise;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _TypeIcon(type: exercise.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _paramsSummary(l10n, exercise.type, item.params),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (item.params.restSeconds != null) ...[
              const SizedBox(width: 8),
              Text(
                l10n.workoutPrepareRest(item.params.restSeconds!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _paramsSummary(
    AppLocalizations l10n,
    ExerciseType type,
    ProgramDayExercise p,
  ) {
    final sets = p.sets;
    final reps = p.reps;
    final weight = p.weightKg;
    final duration = p.durationSeconds;
    final distance = p.distanceMeters;
    switch (type) {
      case ExerciseType.strength:
        final base = sets != null
            ? '$sets × ${reps ?? 0} ${l10n.workoutUnitReps}'
            : l10n.programBuilderNoMetrics;
        if (weight != null && weight > 0) {
          return '$base × ${_fmt(weight)} ${l10n.workoutUnitKg}';
        }
        return base;
      case ExerciseType.plank:
        return sets != null && duration != null
            ? '$sets × $duration ${l10n.workoutUnitSeconds}'
            : l10n.programBuilderNoMetrics;
      case ExerciseType.running:
        return distance != null && duration != null
            ? '${_fmt(distance / 1000)} ${l10n.workoutUnitKm} × '
                  '${_fmt(duration / 60)} ${l10n.workoutUnitMinutes}'
            : l10n.programBuilderNoMetrics;
    }
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final ExerciseType type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (type) {
      ExerciseType.strength => Icons.fitness_center,
      ExerciseType.plank => Icons.self_improvement,
      ExerciseType.running => Icons.directions_run,
    };
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: colorScheme.onSecondaryContainer),
    );
  }
}

String _fmt(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
