import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/features/exercises/ui/muscle_diagram.dart';

/// Панель схемы мускулатуры: спереди и сзади, список мышц с %.
///
/// Используется в конструкторе программы (`ProgramBuilderScreen`).
/// В списке «Не задействованы» показываются только группы без подгрупп.
class MusclePanel extends StatelessWidget {
  const MusclePanel({
    super.key,
    required this.highlights,
    required this.title,
    this.allMuscleGroups = const [],
  });

  final Map<String, double> highlights;
  final String title;
  final List<MuscleGroup> allMuscleGroups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usedKeys = highlights.keys.toSet();
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
              highlights: highlights,
              size: const Size(80, 160),
            ),
            const SizedBox(width: 16),
            MuscleDiagram(
              view: MuscleView.back,
              highlights: highlights,
              size: const Size(80, 160),
            ),
          ],
        ),
        if (highlights.isNotEmpty) ...[
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
          for (final entry in highlights.entries) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _muscleKeyToLabel(allMuscleGroups, entry.key),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    '${(entry.value * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
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

  String _muscleKeyToLabel(List<MuscleGroup> groups, String regionKey) {
    final match = groups.firstWhereOrNull((g) => g.regionKey == regionKey);
    return match?.labelRu ?? regionKey;
  }
}
