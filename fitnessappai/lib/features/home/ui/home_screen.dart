import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/ui/program_thumbnail.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/core/ui/status_badge.dart';
import 'package:fitnessappai/features/home/ui/home_controller.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Домашний экран: активная программа и последние тренировки.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.programRepository,
    this.exerciseRepository,
    this.workoutRepository,
    this.clock,
  });

  final ProgramRepository? programRepository;
  final ExerciseRepository? exerciseRepository;
  final WorkoutRepository? workoutRepository;

  /// Часы для детерминированных тестов: «сегодня» внутри контроллера.
  final DateTime Function()? clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    final programRepository =
        widget.programRepository ?? locator.get<ProgramRepository>();
    final workoutRepository =
        widget.workoutRepository ?? locator.get<WorkoutRepository>();
    _controller = HomeController(
      programRepository: programRepository,
      exerciseRepository:
          widget.exerciseRepository ?? locator.get<ExerciseRepository>(),
      workoutRepository: workoutRepository,
      clock: widget.clock,
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
        title: Text(l10n.navHome),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SignalBuilder(
        builder: (context) {
          final controller = _controller;
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              _buildProgramSection(context),
              const SizedBox(height: 24),
              _buildWorkoutsSection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgramSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = _controller;

    if (!controller.hasPrograms.value) {
      return _EmptyHint(
        icon: Icons.fitness_center_outlined,
        title: l10n.homeNoProgramsTitle,
        hint: l10n.homeNoProgramsHint,
        actionLabel: l10n.homeGoToPrograms,
        onAction: () => context.push('/programs'),
      );
    }

    final programs = controller.activePrograms.value;
    if (programs.isEmpty) {
      return _EmptyHint(
        icon: Icons.star_outline,
        title: l10n.homeActiveProgram,
        hint: l10n.homeNoActiveProgramHint,
        actionLabel: l10n.homeGoToPrograms,
        onAction: () => context.push('/programs'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                programs.length == 1
                    ? l10n.homeActiveProgram
                    : '${l10n.homeActiveProgram} (${programs.length})',
                style: theme.textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/programs'),
              icon: const Icon(Icons.list_alt, size: 18),
              label: Text(l10n.homeGoToPrograms),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final info in programs) ...[
          _ActiveProgramCard(
            programName: info.program.name,
            imagePath: info.program.imagePath,
            day: info.upcomingDay,
            exerciseNames: info.exerciseNames,
            onTap: () => context.push('/programs/${info.program.id}/edit'),
            onStart: info.upcomingDay != null
                ? () => context.push('/workout/prepare/${info.upcomingDay!.id}')
                : null,
            todayStatus: info.todayStatus,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildWorkoutsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = _controller;
    final workouts = controller.recentWorkouts.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.homeRecentWorkouts, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (workouts.isEmpty)
          _EmptyHint(
            icon: Icons.history_outlined,
            title: l10n.homeRecentWorkouts,
            hint: l10n.homeNoWorkoutsHint,
          )
        else ...[
          for (final item in workouts) ...[
            _RecentWorkoutCard(item: item),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/history'),
              child: Text(l10n.homeGoToHistory),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActiveProgramCard extends StatelessWidget {
  const _ActiveProgramCard({
    required this.programName,
    required this.day,
    required this.exerciseNames,
    required this.onTap,
    this.imagePath,
    this.onStart,
    this.todayStatus,
  });

  final String programName;
  final ProgramDay? day;
  final List<String> exerciseNames;
  final VoidCallback onTap;
  final String? imagePath;
  final VoidCallback? onStart;
  final WeekPlanStatus? todayStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProgramThumbnail(imagePath: imagePath),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      programName,
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onStart != null)
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline),
                      tooltip: l10n.weekPlanStart,
                      onPressed: onStart,
                    ),
                ],
              ),
              if (day != null) ...[
                const SizedBox(height: 8),
                if (todayStatus != null)
                  StatusBadge(status: todayStatus!)
                else
                  Text(
                    '${l10n.homeUpcomingDay}: '
                    '${_weekdayLabel(l10n, day!.dayOfWeek)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
              if (exerciseNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final name in exerciseNames)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(name, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentWorkoutCard extends StatelessWidget {
  const _RecentWorkoutCard({required this.item});

  final HomeWorkoutItem item;

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
              Text(
                session.programName,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.hint,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _weekdayLabel(AppLocalizations l10n, int? dayOfWeek) =>
    switch (dayOfWeek) {
      1 => l10n.weekdayMon,
      2 => l10n.weekdayTue,
      3 => l10n.weekdayWed,
      4 => l10n.weekdayThu,
      5 => l10n.weekdayFri,
      6 => l10n.weekdaySat,
      7 => l10n.weekdaySun,
      _ => l10n.homeUpcomingDayNotAssigned,
    };
