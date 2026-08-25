import 'package:flutter/material.dart';

import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/features/exercises/ui/muscle_diagram.dart';
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';

/// Панель схемы мускулатуры: спереди и сзади, иерархический список мышц с %.
///
/// Используется в конструкторе программы (`ProgramBuilderScreen`).
/// Родительские группы показывают суммарный %, подгруппы — долю внутри.
/// В списке «Не задействованы» показываются только группы без подгрупп.
class MusclePanel extends StatelessWidget {
  const MusclePanel({
    super.key,
    required this.loads,
    required this.title,
    required this.allMuscleGroups,
  });

  final List<MuscleGroupLoad> loads;
  final String title;
  final List<MuscleGroup> allMuscleGroups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diagramHighlights = _buildDiagramHighlights(loads);
    final usedKeys = <String>{};
    for (final load in loads) {
      usedKeys.add(load.muscleGroup.regionKey);
      for (final child in load.children) {
        usedKeys.add(child.muscleGroup.regionKey);
      }
    }
    final unused = allMuscleGroups
        .where((g) => !usedKeys.contains(g.regionKey) && g.parentKey == null)
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MuscleDiagram(
              view: MuscleView.front,
              highlights: diagramHighlights,
              size: const Size(80, 160),
            ),
            const SizedBox(width: 16),
            MuscleDiagram(
              view: MuscleView.back,
              highlights: diagramHighlights,
              size: const Size(80, 160),
            ),
          ],
        ),
        if (loads.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Задействованы',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (final load in loads) ...[
            _MuscleGroupTile(load: load),
          ],
        ],
        if (unused.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Не задействованы',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final group in unused)
                Chip(
                  label: Text(group.labelRu, style: theme.textTheme.labelSmall),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MuscleGroupTile extends StatelessWidget {
  const _MuscleGroupTile({required this.load});

  final MuscleGroupLoad load;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChildren = load.children.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  load.muscleGroup.labelRu,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: hasChildren ? FontWeight.w600 : null,
                  ),
                ),
              ),
              Text(
                '${load.percent.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: hasChildren ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
        for (final child in load.children)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    child.muscleGroup.labelRu,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${child.percent.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Map<String, double> _buildDiagramHighlights(List<MuscleGroupLoad> loads) {
  if (loads.isEmpty) {
    return const {};
  }
  final maxPercent = loads.first.percent;
  final highlights = <String, double>{};
  for (final load in loads) {
    final value = maxPercent == 0 ? 0.0 : load.percent / maxPercent;
    final current = highlights[load.muscleGroup.regionKey] ?? 0.0;
    highlights[load.muscleGroup.regionKey] = current > value ? current : value;
  }
  return highlights;
}
