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
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return RefreshIndicator(
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
    return RefreshIndicator(
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
              onStart: item.days.isEmpty
                  ? null
                  : () =>
                        context.push('/workout/prepare/${item.days.first.id}'),
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
    final program = item.program;
    final weekProgress = item.weekProgress;
    final nearest = nearestWeekday(
      weekdays: [for (final day in item.days) day.dayOfWeek],
      todayWeekday: DateTime.now().weekday,
    );
    return AppCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: AppInkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: AppText(
                              l10n.programDaysCount(program.daysCount),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          if (item.exercisesCount > 0) ...[
                            const SizedBox(width: 6),
                            AppContainer(
                              width: 1,
                              height: 10,
                              color: theme.colorScheme.outlineVariant,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: AppText(
                                l10n.programExercisesCount(item.exercisesCount),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                          if (program.isActive) ...[
                            const SizedBox(width: 8),
                            _ActiveBadge(label: l10n.programActive),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProgramThumbnail(
                            imagePath: program.imagePath,
                            size: 56,
                          ),
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
                                if (item.days.any(
                                  (day) => day.dayOfWeek != null,
                                )) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      for (final day in item.days)
                                        if (day.dayOfWeek != null)
                                          _DayBadge(
                                            label: _weekdayLabel(
                                              l10n,
                                              day.dayOfWeek!,
                                            ),
                                          ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppContainer(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: theme.colorScheme.outlineVariant,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (nearest != null)
                          Flexible(
                            child: AppText(
                              '${l10n.homeUpcomingDay}: '
                              '${_weekdayLabel(l10n, nearest)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        PopupMenuButton<String>(
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
                              PopupMenuItem(
                                value: 'deactivate',
                                child: AppText(l10n.programDeactivate),
                              )
                            else
                              PopupMenuItem(
                                value: 'set-active',
                                child: AppText(l10n.programMakeActive),
                              ),
                            PopupMenuItem(
                              value: 'edit',
                              child: AppText(l10n.commonEdit),
                            ),
                            PopupMenuItem(
                              value: 'copy-json',
                              child: AppText(l10n.programCopyJson),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: AppText(l10n.commonDelete),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (weekProgress != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
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
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.primary),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: AppText(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
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
