import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/ui/program_thumbnail.dart';
import 'package:fitnessappai/core/ui/uikit.dart';
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
      appBar: AppBar(leading: const AppMenuButton(), title: Text(l10n.navHome)),
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
        AppSectionHeader(
          title: programs.length == 1
              ? l10n.homeActiveProgram
              : '${l10n.homeActiveProgram} (${programs.length})',
          actionLabel: l10n.homeGoToPrograms,
          onAction: () => context.push('/programs'),
        ),
        const SizedBox(height: 12),
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
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildWorkoutsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller;
    final workouts = controller.recentWorkouts.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n.homeRecentWorkouts,
          actionLabel: workouts.isNotEmpty ? l10n.homeGoToHistory : null,
          onAction: () => context.push('/history'),
        ),
        const SizedBox(height: 12),
        if (workouts.isEmpty)
          _EmptyHint(
            icon: Icons.history_outlined,
            title: l10n.homeRecentWorkouts,
            hint: l10n.homeNoWorkoutsHint,
          )
        else ...[
          for (final item in workouts) ...[
            _RecentWorkoutCard(item: item),
            const SizedBox(height: 10),
          ],
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
    return AppCard(
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.surfaceContainerLow,
          theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgramThumbnail(imagePath: imagePath),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  programName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onStart != null)
                IconButton.filledTonal(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: l10n.weekPlanStart,
                  onPressed: onStart,
                ),
            ],
          ),
          if (day != null) ...[
            const SizedBox(height: 12),
            if (todayStatus != null)
              StatusBadge(status: todayStatus!)
            else
              Text(
                '${l10n.homeUpcomingDay}: '
                '${_weekdayLabel(l10n, day!.dayOfWeek)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
          if (exerciseNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final name in exerciseNames)
                  Chip(
                    avatar: const Icon(Icons.fitness_center, size: 14),
                    label: Text(name, style: theme.textTheme.bodySmall),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  ),
              ],
            ),
          ],
        ],
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
    return AppCard(
      onTap: () => context.push('/history/${session.id}'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.programName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.historyExercisesCount(item.exercisesCount)}'
                  ' · ${l10n.historyDuration(minutes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
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
