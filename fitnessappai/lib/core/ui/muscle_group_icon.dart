import 'package:flutter/material.dart';

/// Виджет для отображения пиктограммы группы мышц на основе добавленных ассетов.
class MuscleGroupIcon extends StatelessWidget {
  const MuscleGroupIcon({
    super.key,
    required this.muscleKey,
    this.size = 24.0,
    this.color,
  });

  /// Ключ мышечной группы (например, 'arms', 'back', 'legs', 'shoulders' / 'shoulders_front', 'chest', 'abs', 'neck', 'rest').
  final String muscleKey;
  final double size;
  final Color? color;

  String _assetPath(String key) {
    // Маппинг ключей на добавленные файлы в assets/images/groups/
    final normalized = key.toLowerCase();
    if (normalized.contains('arm') || normalized.contains('biceps') || normalized.contains('triceps') || normalized.contains('forearm')) {
      return 'assets/images/groups/arm.jpg';
    }
    if (normalized.contains('back') || normalized.contains('lats') || normalized.contains('trap') || normalized.contains('lower_back')) {
      return 'assets/images/groups/back.jpg';
    }
    if (normalized.contains('leg') || normalized.contains('quad') || normalized.contains('hamstring') || normalized.contains('calf') || normalized.contains('glute')) {
      return 'assets/images/groups/legs.jpg';
    }
    if (normalized.contains('shoulder') || normalized.contains('deltoid')) {
      return 'assets/images/groups/shoulder.jpg';
    }
    if (normalized.contains('chest') || normalized.contains('abs') || normalized.contains('oblique')) {
      return 'assets/images/groups/press.jpg';
    }
    if (normalized.contains('neck')) {
      return 'assets/images/groups/neck.jpg';
    }
    return 'assets/images/groups/rest.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final path = _assetPath(muscleKey);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.fitness_center,
            size: size * 0.8,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
