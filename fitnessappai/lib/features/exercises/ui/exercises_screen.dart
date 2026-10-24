import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_list_controller.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_list_item.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_thumbnail.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';

/// Экран списка упражнений: поиск, фильтр по типу, карточки.
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({
    super.key,
    this.repository,
    this.mediaCache,
    this.profileRepository,
  });

  final ExerciseRepository? repository;
  final MediaCache? mediaCache;
  final UserProfileRepository? profileRepository;

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  late final ExerciseListController _controller;
  late final MediaCache _mediaCache;
  final Set<int> _selectedIds = {};

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = ExerciseListController(
      widget.repository ?? locator.get<ExerciseRepository>(),
      profileRepository:
          widget.profileRepository ?? locator.get<UserProfileRepository>(),
    );
    _mediaCache = widget.mediaCache ?? locator.get<MediaCache>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode(int id) {
    setState(() {
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _confirmStartExercise(Exercise exercise) {
    context.push('/exercises/${exercise.id}/params');
  }

  Future<void> _deleteSelected() async {
    final l10n = AppLocalizations.of(context);
    final repo = widget.repository ?? locator.get<ExerciseRepository>();
    final selected = List<int>.from(_selectedIds);

    // Собираем ссылки упражнений в программы.
    final refsByName = <String, Map<String, List<int>>>{};
    for (final id in selected) {
      final programs = await repo.referencedPrograms(id);
      if (programs.isNotEmpty) {
        final name = (await repo.getById(id))?.name ?? '$id';
        refsByName[name] = programs;
      }
    }

    if (!mounted) {
      return;
    }

    String? warning;
    if (refsByName.isNotEmpty) {
      final buffer = StringBuffer();
      for (final entry in refsByName.entries) {
        final programList = entry.value.entries
            .map(
              (p) => '${p.key} (Дни ${p.value.map((d) => d + 1).join(', ')})',
            )
            .join(', ');
        buffer.writeln('• ${entry.key} → $programList');
      }
      warning =
          '${l10n.exerciseListDeleteWarning}\n\n${buffer.toString().trim()}';
    }

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: AppText(l10n.exerciseListDeleteTitle(selected.length)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (warning != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppText(
                  warning,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (refsByName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppText(
                  l10n.exerciseListDeleteBlockedHint,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            AppText(l10n.exerciseListDeleteConfirm(selected.length)),
          ],
        ),
        actions: [
          AppTextButton(
            label: MaterialLocalizations.of(context).cancelButtonLabel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            onPressed: refsByName.isEmpty
                ? () => Navigator.of(context).pop(true)
                : null,
            label: l10n.exerciseListDeleteButton,
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    for (final id in selected) {
      await repo.delete(id);
    }
    _exitSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      appBar: AppTopBar(
        // Крупный заголовок только вне режима выделения (там — счётчик).
        large: !_selectionMode,
        title: _selectionMode ? '${_selectedIds.length}' : l10n.navExercises,
        leading: _selectionMode
            ? AppIconButton(
                icon: const AppIcon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : const AppMenuButton(),
        actions: _selectionMode
            ? [
                AppIconButton(
                  icon: const AppIcon(Icons.delete),
                  onPressed: _deleteSelected,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              hintText: l10n.exerciseListHint,
              leading: const AppIcon(Icons.search),
              onChanged: _controller.setQuery,
            ),
          ),
          _buildTypeFilters(context),
          // Отдельная строка с тумблером (54.7, образец «Упражнения»):
          // «только свои» — не фильтр-чип, а режим списка на всю ширину.
          // Тап по всей строке + семантика toggled (design-review 54.7).
          SignalBuilder(
            builder: (context) {
              final onlyCustom = _controller.onlyCustom.value;
              void toggle() => _controller.setOnlyCustom(!onlyCustom);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: AppInkWell(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  onTap: toggle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppText(
                            l10n.exerciseListOnlyCustom,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Semantics(
                          container: true,
                          excludeSemantics: true,
                          label: l10n.exerciseListOnlyCustom,
                          toggled: onlyCustom,
                          child: AppSwitch(
                            value: onlyCustom,
                            onChanged: _controller.setOnlyCustom,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: SignalBuilder(builder: (context) => _buildBody(context)),
          ),
        ],
      ),
      floatingActionButton: AppTooltip(
        message: l10n.exerciseListCreate,
        child: AppGlowContainer(
          radius: AppRadii.lg,
          child: AppContainer(
            width: 56,
            height: 56,
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryCta,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: AppInkWell(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              onTap: () => context.push('/exercises/new'),
              child: Center(
                child: AppIcon(
                  Icons.add,
                  size: 28,
                  // На градиенте primaryCta — всегда белый (см. токен:
                  // onPrimary тёмной темы даёт ~2.2:1, дизайн-ревью 54.9).
                  color: AppColors.primaryCtaContent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SignalBuilder(
      builder: (context) {
        final current = _controller.typeFilter.value;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              for (final option in <ExerciseType?>[
                null,
                ...ExerciseType.values,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterPill(
                    label: option == null
                        ? l10n.exerciseFilterAll
                        : _typeLabel(l10n, option),
                    selected: current == option,
                    onTap: () => _controller.setTypeFilter(option),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = _controller.items.value;
    if (_controller.isLoading.value && items.isEmpty) {
      return const Center(child: AppSpinner());
    }
    if (items.isEmpty) {
      return AppRefresh(
        onRefresh: _controller.refresh,
        child: AppListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 160),
            AppEmptyState(
              icon: Icons.fitness_center_outlined,
              title: l10n.exerciseListEmpty,
              hint: l10n.exerciseListEmptyHint,
            ),
          ],
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
          final id = item.exercise.id!;
          final selected = _selectedIds.contains(id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ExerciseCard(
              item: item,
              mediaCache: _mediaCache,
              selected: selected,
              selectionMode: _selectionMode,
              onTap: () {
                if (_selectionMode) {
                  _toggleSelection(id);
                } else {
                  context.push('/exercises/$id');
                }
              },
              onLongPress: () => _enterSelectionMode(id),
              onStart: _selectionMode
                  ? null
                  : () => _confirmStartExercise(item.exercise),
            ),
          );
        },
      ),
    );
  }
}

String _typeLabel(AppLocalizations l10n, ExerciseType type) => switch (type) {
  ExerciseType.strength => l10n.exerciseTypeStrength,
  ExerciseType.bodyweight => l10n.exerciseTypeBodyweight,
  ExerciseType.plank => l10n.exerciseTypePlank,
  ExerciseType.distance => l10n.exerciseTypeDistance,
};

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.item,
    required this.mediaCache,
    required this.onTap,
    required this.onLongPress,
    this.selected = false,
    this.selectionMode = false,
    this.onStart,
  });

  final ExerciseListItem item;
  final MediaCache mediaCache;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selected;
  final bool selectionMode;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final exercise = item.exercise;
    return AppCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: AppInkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AppCheckbox(
                    value: selected,
                    onChanged: (_) => onTap(),
                  ),
                ),
              ExerciseThumbnail(
                exercise: exercise,
                mediaCache: mediaCache,
                size: 56,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      // Две строки (design-review 54.7): длинные названия
                      // не обрываются на fontScale 1.0–1.3.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Badge(label: _typeLabel(l10n, exercise.type)),
                        // Иконки групп (54.7, образец): до трёх пиктограмм
                        // с дедупом по ассету — дубли «грудь/пресс» не рисуем.
                        for (final key in MuscleGroupIcon.dedupeByAsset(
                          item.muscles.map((m) => m.key),
                        ).take(3))
                          MuscleGroupIcon(muscleKey: key, size: 18),
                        if (item.hasContraindications)
                          _Badge(
                            label: l10n.contraindications,
                            icon: Icons.warning_amber_rounded,
                            highlight: true,
                          ),
                      ],
                    ),
                    if (item.muscles.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      AppText(
                        item.muscles.map((m) => m.labelRu).join(', '),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onStart != null) ...[
                const SizedBox(width: 8),
                // Градиентная play-кнопка (54.7, образец): круг на
                // primaryCta. Glow не рисуем — на каждой карточке он
                // конкурирует с primary-FAB (design-review 54.7); тап-таргет
                // 48dp и роль button — через Tooltip+Semantics.
                AppTooltip(
                  message: l10n.exerciseListStartWorkout,
                  child: Semantics(
                    button: true,
                    label: l10n.exerciseListStartWorkout,
                    child: AppContainer(
                      width: 48,
                      height: 48,
                      padding: EdgeInsets.zero,
                      decoration: const BoxDecoration(
                        gradient: AppGradients.primaryCta,
                        shape: BoxShape.circle,
                      ),
                      child: AppInkWell(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        onTap: onStart,
                        child: Center(
                          child: AppIcon(
                            Icons.play_arrow,
                            size: 26,
                            // На градиенте primaryCta — всегда белый (токен,
                            // design-review 54.9).
                            color: AppColors.primaryCtaContent,
                          ),
                        ),
                      ),
                    ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.icon, this.highlight = false});

  final String label;
  final IconData? icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = highlight
        ? colorScheme.errorContainer
        : colorScheme.secondaryContainer;
    final foreground = highlight
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;
    return AppContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        // Пилюля (54.7): бейджи списка — как статус-чипи 54.4–54.6.
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon, size: 13, color: foreground),
            const SizedBox(width: 3),
          ],
          AppText(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// Пилюля-фильтр по типу (54.7, образец «Упражнения»): выбранная —
/// неон-обводка и свечение [AppGlowContainer], невыбранная — plain-чип.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chip = FilterChip(
      label: AppText(label),
      selected: selected,
      showCheckmark: selected,
      onSelected: (_) => onTap(),
    );
    if (!selected) {
      return chip;
    }
    return AppGlowContainer(
      radius: AppRadii.pill,
      padding: EdgeInsets.zero,
      child: chip,
    );
  }
}
