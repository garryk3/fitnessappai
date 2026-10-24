import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/home/ui/home_controller.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_thumbnail.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/status_badge.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';
import 'package:fitnessappai/uikit/uikit.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';

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
    return AppScaffold(
      appBar: AppTopBar(
        leading: const AppMenuButton(),
        title: l10n.navHome,
        large: true,
      ),
      body: SignalBuilder(
        builder: (context) {
          final controller = _controller;
          if (controller.isLoading.value) {
            return const Center(child: AppSpinner());
          }
          return AppListView(
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
      return AppEmptyState(
        icon: Icons.fitness_center_outlined,
        title: l10n.homeNoProgramsTitle,
        hint: l10n.homeNoProgramsHint,
        actionLabel: l10n.homeGoToPrograms,
        onAction: () => context.push('/programs'),
      );
    }

    final programs = controller.activePrograms.value;
    if (programs.isEmpty) {
      return AppEmptyState(
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
            weeklyProgressPercent: info.weeklyProgressPercent,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildWorkoutsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = _controller;
    final workouts = controller.recentWorkouts.value;
    final int streak = controller.streakDays.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Стрик (54.3): только при живой серии — «Серия: 0 дней» не показываем
        // (правило «без данных — без элементов»).
        if (streak >= 1) ...[
          AppBadge(
            label: l10n.homeStreakDays(streak),
            icon: Icons.local_fire_department,
            background: theme.colorScheme.primaryContainer.withValues(
              alpha: AppTints.faint,
            ),
            foreground: theme.colorScheme.primary,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadii.pill),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          const SizedBox(height: 12),
        ],
        AppSectionHeader(
          title: l10n.homeRecentWorkouts,
          actionLabel: workouts.isNotEmpty ? l10n.homeGoToHistory : null,
          onAction: () => context.go('/history'),
        ),
        const SizedBox(height: 12),
        if (workouts.isEmpty)
          AppEmptyState(
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
    this.weeklyProgressPercent,
  });

  final String programName;
  final ProgramDay? day;
  final List<String> exerciseNames;
  final VoidCallback onTap;
  final String? imagePath;
  final VoidCallback? onStart;
  final WeekPlanStatus? todayStatus;

  /// Процент выполнения программы за неделю или `null`, когда считать нечего
  /// (у программы нет дней). Значение может быть больше 100 — так считается
  /// прогресс программы с непривязанными днями (48.2).
  final int? weeklyProgressPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Hero-фон (54.3): в тёмной теме — тёмный градиент-токен по образцу
    // (белый текст ≥4.5:1, проверяется `app_tokens_test`); светлая тема
    // остаётся без near-black поверхностей (DESIGN.md §11) — лёгкий
    // ролевой градиент (токен, переиспользуется stat-карточкой 54.8).
    final bool isDark = theme.brightness == Brightness.dark;
    final Gradient heroGradient = isDark
        ? AppGradients.heroCard
        : AppGradients.roleSurface(theme.colorScheme);

    return AppGlowContainer(
      radius: AppRadii.xl,
      child: AppCard(
        gradient: heroGradient,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProgramThumbnail(imagePath: imagePath),
                const SizedBox(width: 14),
                Expanded(
                  child: AppText(
                    programName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    // Две строки: строка делит ширину с миниатюрой и
                    // кольцом — на обычном масштабе имя программы не
                    // должно обрезаться (54.3, design-review).
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (weeklyProgressPercent != null) ...[
                  AppProgressRing(
                    percent: weeklyProgressPercent!,
                    label: l10n.homeWeekProgressLabel(weeklyProgressPercent!),
                  ),
                ],
              ],
            ),
            if (day != null) ...[
              const SizedBox(height: 12),
              if (todayStatus != null)
                StatusBadge(status: todayStatus!)
              else
                AppText(
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
                    AppChip(
                      avatar: const AppIcon(Icons.fitness_center, size: 14),
                      label: AppText(name, style: theme.textTheme.bodySmall),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    ),
                ],
              ),
            ],
            if (onStart != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: AppGradientButton(
                  label: l10n.weekPlanStart,
                  icon: Icons.play_arrow,
                  pill: true,
                  onPressed: onStart,
                ),
              ),
            ],
          ],
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
    // Рестайл 54.3 по образцу: программа/дата/упражнения слева, крупная
    // длительность titleLarge справа.
    return AppCard(
      onTap: () => context.push('/history/${session.id}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  session.programName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                AppText(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  l10n.historyExercisesCount(item.exercisesCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppText(
            l10n.historyDuration(minutes),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
