// ignore_for_file: type=lint
import 'package:flutter/material.dart';

import 'package:fitnessappai/app/theme/app_tokens.dart';

/// Кнопка UI-кита: градиент и эффект свечения (редизайн 54, DESIGN.md §11).
///
/// Дефолтный градиент — токен [AppGradients.primaryCta] (фиолет → синий,
/// белый текст ≥4.5:1 на всём протяжении). Свечение — токены [AppGlow],
/// рисуется только в тёмной теме (светлая — без glow, §11). Неактивная
/// кнопка (`onPressed == null`) отличима: нейтральная подложка
/// `surfaceContainerHigh` вместо градиента, текст `onSurfaceVariant`,
/// без свечения; `busy` — отдельное состояние на градиенте (54.3).
class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.gradient,
    this.busy = false,
    this.pill = false,
    this.intensity = 1.0,
  });

  /// Текст кнопки; при [busy] заменяется спиннером.
  final String label;

  /// null — кнопка неактивна.
  final VoidCallback? onPressed;

  final IconData? icon;

  /// Свой градиент вместо [AppGradients.primaryCta].
  final Gradient? gradient;

  /// true — спиннер вместо текста, кнопка неактивна (сохранение).
  final bool busy;

  /// true — пилюля (stadium), false — скругление `AppRadii.lg`.
  final bool pill;

  /// Интенсивность свечения (`AppGlow.alpha * intensity`); только тёмная тема.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Gradient effectiveGradient = gradient ?? AppGradients.primaryCta;
    final BorderRadius borderRadius = BorderRadius.circular(
      pill ? AppRadii.pill : AppRadii.lg,
    );
    // Disabled (54.3): `onPressed == null` — нейтральная подложка вместо
    // градиента и приглушённый текст — неактивная кнопка отличима от
    // активной. `busy` — отдельное состояние: кнопка на градиенте
    // со спиннером, свечение сохраняется.
    final bool disabled = onPressed == null && !busy;
    final bool glow = theme.brightness == Brightness.dark && !disabled;

    final BoxDecoration decoration = disabled
        ? BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: borderRadius,
          )
        : BoxDecoration(
            gradient: effectiveGradient,
            borderRadius: borderRadius,
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(
                        alpha: AppGlow.alpha * intensity,
                      ),
                      blurRadius: AppGlow.radius,
                      spreadRadius: AppGlow.spread,
                    ),
                  ]
                : const [],
          );

    return DecoratedBox(
      decoration: decoration,
      child: ElevatedButton.icon(
        onPressed: (onPressed != null && !busy) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        icon: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                // Белый: дефолтный `primary` на светлом градиенте
                // (контраст ~1.02:1) не виден — спиннер «висит» (54.3,
                // design-review); текст на кнопке всегда белый (§11).
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : icon != null
            ? Icon(icon)
            : const SizedBox.shrink(),
        label: busy ? const SizedBox.shrink() : Text(label),
      ),
    );
  }
}
