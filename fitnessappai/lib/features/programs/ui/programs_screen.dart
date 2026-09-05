import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/notifications/reminder_service.dart';
import 'package:fitnessappai/features/llm/data/llm_export_service.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_list_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Экран списка программ: карточки с днями и упражнениями.
class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key, this.repository, this.reminderService});

  final ProgramRepository? repository;
  final ReminderService? reminderService;

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
      appBar: AppBar(title: Text(l10n.navPrograms)),
      body: SignalBuilder(builder: (context) => _buildBody(context)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'programs-fab',
        onPressed: () => context.push('/programs/new'),
        tooltip: l10n.programListCreate,
        child: const Icon(Icons.add),
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
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: Center(
                  child: Text(AppLocalizations.of(context).programListEmpty),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView.builder(
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
      messenger.showSnackBar(SnackBar(content: Text(l10n.copyJsonNotFound)));
      return;
    }
    await Clipboard.setData(ClipboardData(text: json));
    messenger.showSnackBar(SnackBar(content: Text(l10n.copyJsonCopied)));
  }

  Future<void> _confirmDelete(BuildContext context, Program program) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commonDelete),
        content: Text(l10n.programDeleteConfirm(program.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                program.name,
                                style: theme.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (program.isActive) ...[
                              const SizedBox(width: 8),
                              _ActiveBadge(label: l10n.programActive),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.programDaysCount(program.daysCount),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (item.days.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final day in item.days)
                                _DayBadge(
                                  label: _weekdayLabel(l10n, day.dayOfWeek),
                                ),
                            ],
                          ),
                        ],
                        if (item.exercisesCount > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            l10n.programExercisesCount(item.exercisesCount),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
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
                          child: Text(l10n.programDeactivate),
                        )
                      else
                        PopupMenuItem(
                          value: 'set-active',
                          child: Text(l10n.programMakeActive),
                        ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.commonEdit),
                      ),
                      PopupMenuItem(
                        value: 'copy-json',
                        child: Text(l10n.programCopyJson),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.commonDelete),
                      ),
                    ],
                  ),
                ],
              ),
              if (onStart != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.weekPlanStart),
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

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
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
