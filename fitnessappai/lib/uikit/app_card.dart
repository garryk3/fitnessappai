// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Карточка UI-кита: радиус 20 и мягкая тень.
///
/// Материальный [Card] разрешён только внутри `lib/uikit/`; в UI приложения
/// используйте [AppCard] (иначе падает правило `ban_card_widget`).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.borderColor,
    this.color,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? borderColor;

  /// Фон карточки; `null` — `colorScheme.surfaceContainerLow`.
  /// При заданном [gradient] фон берётся из градиента, [color] игнорируется.
  final Color? color;

  /// Как обрезать содержимое по форме карточки (напр. [Clip.antiAlias]
  /// для графиков с закруглёнными краями). По умолчанию не обрезается.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(20);
    final Widget content = Padding(padding: padding, child: child);

    return Container(
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? (color ?? theme.colorScheme.surfaceContainerLow)
            : null,
        borderRadius: borderRadius,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        // InkWell добавляем только при обработчике: мёртвый (onTap: null)
        // слой-перехватчик лишь участвует в жестовом арене и усложняет
        // поиск `byType(InkWell)` внутри карточки. Material остаётся всегда —
        // им пользуются дочерние InkWell.
        child: onTap == null
            ? content
            : InkWell(borderRadius: borderRadius, onTap: onTap, child: content),
      ),
    );
  }
}
