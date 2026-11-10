import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/nearest_weekday.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/llm/data/llm_export_service.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_list_controller.dart';
import 'package:fitnessappai/features/programs/ui/program_thumbnail.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';

/// Экран списка программ: карточки с днями и упражнениями.
class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({
    super.key,
    this.repository,
    this.reminderService,
    this.workoutRepository,
  });

  final ProgramRepository? repository;
  final ReminderService? reminderService;

  /// Репозиторий сессий — для недельного прогресса карточек (кольцо %).
  /// `null` — ищется в DI; если DI тоже пуст, кольцо не показывается.
  final WorkoutRepository? workoutRepository;

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  late final ProgramListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProgramListController(
      widget.repository ?? locator.get<ProgramRepository>(),
      reminderService: widget.reminderService,
      workoutRepository:
          widget.workoutRepository ??
          (locator.isRegistered<WorkoutRepository>()
              ? locator.get<WorkoutRepository>()
              : null),
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
        title: l10n.navPrograms,
        large: true,
      ),
      body: SignalBuilder(builder: (context) => _buildBody(context)),
      floatingActionButton: AppFab(
        heroTag: 'programs-fab',
        onPressed: () => context.push('/programs/new'),
        tooltip: l10n.programListCreate,
        icon: Icons.add,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final items = _controller.items.value;
    if (_controller.isLoading.value && items.isEmpty) {
      return const Center(child: AppSpinner());
    }
    if (items.isEmpty) {
      return AppRefresh(
        onRefresh: _controller.refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => AppListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: Center(
                  child: AppText(AppLocalizations.of(context).programListEmpty),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return AppRefresh(
      onRefresh: _controller.refresh,
      child: AppListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ProgramCard(
              item: item,
              onStart: item.program.isActive && item.days.isNotEmpty
                  ? () => context.push('/workout/prepare/${item.days.first.id}')
                  : null,
              onEdit: () => context.push('/programs/${item.program.id}/edit'),
              onDelete: () => _confirmDelete(context, item.program),
              onCopyJson: () => _copyProgramJson(context, item.program),
              onSetActive: () => _makeActive(context, item.program),
              onDeactivate: () => _deactivate(context, item.program),
            ),
          );
        },
      ),
    );
  }

  Future<void> _makeActive(BuildContext context, Program program) async {
    await _controller.setActive(program.id!);
  }

  Future<void> _deactivate(BuildContext context, Program program) async {
    await _controller.deactivate(program.id!);
  }

  Future<void> _copyProgramJson(BuildContext context, Program program) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final json = await locator.get<LlmExportService>().programToJson(
      program.id!,
    );
    if (json == null) {
      showAppSnackBar(messenger, l10n.copyJsonNotFound);
      return;
    }
    await Clipboard.setData(ClipboardData(text: json));
    showAppSnackBar(messenger, l10n.copyJsonCopied);
  }

  Future<void> _confirmDelete(BuildContext context, Program program) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: AppText(l10n.commonDelete),
        content: AppText(l10n.programDeleteConfirm(program.name)),
        actions: [
          AppTextButton(
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: l10n.commonDelete,
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _controller.deleteProgram(program.id!);
      await _controller.refresh();
    }
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.item,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
    required this.onCopyJson,
    required this.onSetActive,
    required this.onDeactivate,
  });

  final ProgramListItem item;
  final VoidCallback? onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCopyJson;
  final VoidCallback onSetActive;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final program = item.program;
    final weekProgress = item.weekProgress;
    final nearest = nearestWeekday(
      weekdays: [for (final day in item.days) day.dayOfWeek],
      todayWeekday: DateTime.now().weekday,
    );
    return AppCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 60.1: вертикальная композиция вместо Row с правой колонкой —
          // на узких экранах боковая колонка выжимала и обрезала имя/мету.
          // Приоритет контента: mini-фото + имя (Expanded) + меню.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgramThumbnail(imagePath: program.imagePath, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      program.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Мета + маркировка активности (60.1): Wrap, чтобы строка
                    // переносилась, а не обрезалась на узких экранах.
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (program.isActive)
                          AppBadge(
                            label: l10n.programActive,
                            background: colorScheme.primaryContainer.withValues(
                              alpha: AppTints.faint,
                            ),
                            foreground: colorScheme.primary,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(AppRadii.pill),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          )
                        else
                          AppBadge(
                            label: l10n.programInactive,
                            background: theme.colorScheme.surfaceContainerHigh,
                            foreground: colorScheme.onSurfaceVariant,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(AppRadii.pill),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          ),
                        AppText(
                          l10n.programDaysCount(program.daysCount),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.4,
                          ),
                        ),
                        if (item.exercisesCount > 0)
                          AppText(
                            l10n.programExercisesCount(item.exercisesCount),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 0.4,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              AppPopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  } else if (value == 'copy-json') {
                    onCopyJson();
                  } else if (value == 'set-active') {
                    onSetActive();
                  } else if (value == 'deactivate') {
                    onDeactivate();
                  }
                },
                itemBuilder: (context) => [
                  if (program.isActive)
                    AppPopupMenuItem(
                      value: 'deactivate',
                      child: AppText(l10n.programDeactivate),
                    )
                  else
                    AppPopupMenuItem(
                      value: 'set-active',
                      child: AppText(l10n.programMakeActive),
                    ),
                  AppPopupMenuItem(
                    value: 'edit',
                    child: AppText(l10n.commonEdit),
                  ),
                  AppPopupMenuItem(
                    value: 'copy-json',
                    child: AppText(l10n.programCopyJson),
                  ),
                  AppPopupMenuItem(
                    value: 'delete',
                    child: AppText(l10n.commonDelete),
                  ),
                ],
              ),
            ],
          ),
          if (item.days.any((day) => day.dayOfWeek != null)) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final day in item.days)
                  if (day.dayOfWeek != null)
                    _DayBadge(label: _weekdayLabel(l10n, day.dayOfWeek!)),
              ],
            ),
          ],
          if (nearest != null || weekProgress != null || onStart != null) ...[
            const SizedBox(height: 12),
            // Ближайший день и недельный прогресс — в подвале слева,
            // кнопка «Начать» — справа; тесноты узкого экрана больше нет.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (nearest != null)
                        AppText(
                          '${l10n.homeUpcomingDay}: ${_weekdayLabel(l10n, nearest)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (weekProgress != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppProgressRing(
                              percent: item.weekPercent!,
                              label: l10n.homeWeekProgressLabel(
                                item.weekPercent!,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppText(
                              l10n.programListWeekFraction(
                                weekProgress.performed,
                                weekProgress.assigned,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (onStart != null)
                  AppGradientButton(
                    pill: true,
                    icon: Icons.play_arrow,
                    label: l10n.weekPlanStart,
                    onPressed: onStart,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: AppText(
        label ?? '',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
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
      _ => '',
    };
