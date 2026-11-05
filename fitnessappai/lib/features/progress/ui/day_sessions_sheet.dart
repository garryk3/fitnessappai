import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fitnessappai/app/theme/app_tokens.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/ui/program_thumbnail.dart';
import 'package:fitnessappai/features/progress/ui/history_controller.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

/// Заголовок деталей дня/периода: одна дата или диапазон.
String dayDetailTitle(DateTime start, DateTime end) {
  final format = DateFormat('d MMMM yyyy', 'ru');
  if (end.isAfter(start.add(const Duration(days: 1)))) {
    return '${format.format(start)} — ${format.format(end.subtract(const Duration(days: 1)))}';
  }
  return format.format(start);
}

/// Открывает нижний дравер с сессиями дня/периода (59.2).
///
/// Тап по дню в истории и по колонке графика прогресса больше не ведёт на
/// отдельную страницу — контент деталей дня показывается в bottom sheet.
Future<void> showDaySessionsSheet(
  BuildContext context, {
  required DateTime start,
  required DateTime end,
  WorkoutRepository? workoutRepository,
  ProgramRepository? programRepository,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      // Поджимание под контент с потолком 60% экрана (design-review 59.2):
      // при 1–2 сессиях дравер не оставляет пустое дно, при длинном
      // списке ограничивается и прокручивается внутри.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок с датой/диапазоном — как в дравере «Плана»
            // (design-review 59.2, High): срезы графика «Прогресса» —
            // неделя/месяц, диапазон должен быть виден целиком.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: AppText(
                dayDetailTitle(start, end),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: DaySessionsContent(
                start: start,
                end: end,
                workoutRepository: workoutRepository,
                programRepository: programRepository,
                shrinkWrap: true,
                // Тап по сессии из дравера: сначала закрыть sheet, затем
                // открыть детали сессии.
                onSessionTap: () => Navigator.of(sheetContext).pop(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Контент деталей дня: сессии в диапазоне `[start, end)`.
///
/// Переиспользуется экраном [DayDetailScreen] (deep-link `/progress/day`)
/// и дравером [showDaySessionsSheet] (59.2). В недельном периоде срез —
/// один день, в месячном — неделя, в годовом — месяц.
class DaySessionsContent extends StatefulWidget {
  const DaySessionsContent({
    super.key,
    required this.start,
    required this.end,
    this.workoutRepository,
    this.programRepository,
    this.shrinkWrap = false,
    this.onSessionTap,
  });

  final DateTime start;
  final DateTime end;
  final WorkoutRepository? workoutRepository;
  final ProgramRepository? programRepository;

  /// `true` — контент внутри bottom sheet: список поджимается под контент,
  /// loading/empty — компактной фиксированной высоты.
  final bool shrinkWrap;

  /// Вызывается перед переходом к деталям сессии; в дравере закрывает sheet.
  /// `null` — переход без закрытия (экран деталей дня).
  final VoidCallback? onSessionTap;

  @override
  State<DaySessionsContent> createState() => _DaySessionsContentState();
}

class _DaySessionsContentState extends State<DaySessionsContent> {
  late final WorkoutRepository _repository;
  late final ProgramRepository? _programRepository;
  List<HistoryItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.workoutRepository ?? locator.get<WorkoutRepository>();
    try {
      _programRepository =
          widget.programRepository ?? locator.get<ProgramRepository>();
    } catch (_) {
      _programRepository = widget.programRepository;
    }
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
      result.add(
        HistoryItem(
          session: session,
          exercisesCount: count,
          imagePath: await _imagePathOf(session),
          // 58.2: тренированное время (временные подходы), не wall-clock
          // ввода метрик — как и на карточках истории.
          displayDuration: detail == null
              ? null
              : workoutDisplayDuration(session, detail.results),
        ),
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _items = result;
      _loading = false;
    });
  }

  Future<String?> _imagePathOf(WorkoutSession session) async {
    final programId = session.programId;
    final repository = _programRepository;
    if (programId == null || repository == null) {
      return null;
    }
    final program = await repository.getProgram(programId);
    return program?.program.imagePath;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget content;
    if (_loading) {
      content = widget.shrinkWrap
          // Компактный loading в дравере: дравер не распахивается на
          // 60% экрана на время загрузки.
          ? const SizedBox(height: 160, child: Center(child: AppSpinner()))
          : const Center(child: AppSpinner());
    } else if (_items.isEmpty) {
      content = widget.shrinkWrap
          ? SizedBox(
              height: 240,
              child: AppEmptyState(
                icon: Icons.calendar_month_outlined,
                title: l10n.progressDayEmpty,
                hint: l10n.progressDayEmptyHint,
              ),
            )
          : AppEmptyState(
              icon: Icons.calendar_month_outlined,
              title: l10n.progressDayEmpty,
              hint: l10n.progressDayEmptyHint,
            );
    } else {
      content = AppListView.separated(
        shrinkWrap: widget.shrinkWrap,
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _SessionCard(item: _items[index], onOpen: widget.onSessionTap),
      );
    }
    return content;
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.item, this.onOpen});

  final HistoryItem item;

  /// См. [DaySessionsContent.onSessionTap].
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = item.session;
    final date = DateFormat('d MMMM yyyy', 'ru').format(session.performedDate);
    final minutes = item.duration.inMinutes;
    return AppCard(
      padding: EdgeInsets.zero,
      child: AppInkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: () {
          onOpen?.call();
          context.push('/history/${session.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProgramThumbnail(imagePath: item.imagePath, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          session.programName,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          date,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          '${l10n.historyExercisesCount(item.exercisesCount)}'
                          ' · ${l10n.historyDuration(minutes)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (session.variant == WorkoutVariant.alternative)
                    AppChip(
                      visualDensity: VisualDensity.compact,
                      label: AppText(
                        l10n.programBuilderAlternativeSet,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
