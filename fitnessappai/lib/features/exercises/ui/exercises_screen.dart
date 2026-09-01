import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_list_controller.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_list_item.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

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
    final refsByName = <String, List<String>>{};
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
        buffer.writeln('• ${entry.key} → ${entry.value.join(', ')}');
      }
      warning =
          '${l10n.exerciseListDeleteWarning}\n\n${buffer.toString().trim()}';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exerciseListDeleteTitle(selected.length)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (warning != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  warning,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (refsByName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.exerciseListDeleteBlockedHint,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Text(l10n.exerciseListDeleteConfirm(selected.length)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: refsByName.isEmpty
                ? () => Navigator.of(context).pop(true)
                : null,
            child: Text(l10n.exerciseListDeleteButton),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('${_selectedIds.length}')
            : Text(l10n.navExercises),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: _selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
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
              leading: const Icon(Icons.search),
              onChanged: _controller.setQuery,
            ),
          ),
          _buildTypeFilters(context),
          SignalBuilder(
            builder: (context) => SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(l10n.exerciseListOnlyCustom),
              value: _controller.onlyCustom.value,
              onChanged: _controller.setOnlyCustom,
            ),
          ),
          Expanded(
            child: SignalBuilder(builder: (context) => _buildBody(context)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'exercises-fab',
        onPressed: () => context.push('/exercises/new'),
        tooltip: l10n.exerciseListCreate,
        child: const Icon(Icons.add),
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
                  child: FilterChip(
                    label: Text(
                      option == null
                          ? l10n.exerciseFilterAll
                          : _typeLabel(l10n, option),
                    ),
                    selected: current == option,
                    onSelected: (_) => _controller.setTypeFilter(option),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 160),
            Center(child: Text(l10n.exerciseListEmpty)),
          ],
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
  ExerciseType.running => l10n.exerciseTypeRunning,
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
    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(value: selected, onChanged: (_) => onTap()),
                ),
              _Thumbnail(exercise: exercise, mediaCache: mediaCache),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Badge(label: _typeLabel(l10n, exercise.type)),
                        if (item.hasContraindications) ...[
                          const SizedBox(width: 6),
                          _Badge(
                            label: l10n.contraindications,
                            icon: Icons.warning_amber_rounded,
                            highlight: true,
                          ),
                        ],
                      ],
                    ),
                    if (item.muscles.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
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
                IconButton(
                  icon: const Icon(Icons.play_circle_outline),
                  tooltip: AppLocalizations.of(
                    context,
                  ).exerciseListStartWorkout,
                  onPressed: onStart,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.exercise, required this.mediaCache});

  final Exercise exercise;
  final MediaCache mediaCache;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    final provider = mediaCache.imageFor(
      exercise.thumbnailPath ?? exercise.animationPath,
      blob: exercise.thumbnailBlob ?? exercise.animationBlob,
      cacheWidth: 112,
    );
    if (provider == null) {
      return _placeholder(context, size);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image(
        image: provider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(context, size),
      ),
    );
  }

  Widget _placeholder(BuildContext context, double size) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.fitness_center, color: colorScheme.onSurfaceVariant),
    );
  }
}
