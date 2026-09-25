import 'package:flutter/material.dart';

/// Чип-бейдж UI-кита: компактная плашка с фоном, текстом и опциональной
/// иконкой. Без бизнес-логики — цвет и текст задаёт вызывающий код.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.border,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.iconSize = 13,
  });

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;
  final Border? border;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius,
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
