// ignore_for_file: type=lint
import 'package:flutter/material.dart';

import 'package:fitnessappai/uikit/app_icon.dart';
import 'package:fitnessappai/uikit/app_text.dart';

/// Основная кнопка UI-кита (filled).
///
/// Материальные кнопки разрешены только внутри `lib/uikit/`; в UI приложения
/// используйте [AppButton] (иначе падает правило `ban_elevated_button_widget`).
/// Градиентная CTA-кнопка — [AppGradientButton], текстовая — [AppTextButton],
/// контурная — [AppOutlinedButton].
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
    this.expanded = false,
    this.autofocus = false,
    this.tooltip,
    this.tonal = false,
    this.pending = false,
    this.visualDensity,
    this.padding,
  });

  /// Подпись кнопки; при [busy] заменяется спиннером.
  final String label;

  /// `null` — кнопка неактивна.
  final VoidCallback? onPressed;

  /// Необязательная иконка перед подписью.
  final IconData? icon;

  /// `true` — спиннер вместо подписи, кнопка неактивна.
  final bool busy;

  /// `true` — кнопка растягивается на всю ширину.
  final bool expanded;

  final bool autofocus;

  /// Всплывающая подсказка (long-press).
  final String? tooltip;

  /// `true` — приглушённый (tonal) вариант Material 3: заливка
  /// `surfaceContainerHighest`, текст `onSurfaceVariant`; вторичные
  /// действия без градиентного акцента.
  final bool tonal;

  /// `true` — спиннер вместо иконки, кнопка неактивна (фоновая операция
  /// при сохранении подписи; для отключения подписи используйте [busy]).
  final bool pending;

  final VisualDensity? visualDensity;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy && !pending;
    final effective = enabled ? onPressed : null;
    final Widget labelWidget = busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : AppText(label);

    final Widget? iconWidget = switch ((busy, pending, icon)) {
      (true, _, _) => null,
      (false, true, _) when icon != null => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      _ when icon != null => AppIcon(icon!),
      _ => null,
    };

    final Widget button = switch ((tonal, iconWidget)) {
      (false, null) => FilledButton(
        onPressed: effective,
        autofocus: autofocus,
        style: _styleOverride,
        child: labelWidget,
      ),
      (false, final Widget _) => FilledButton.icon(
        onPressed: effective,
        autofocus: autofocus,
        style: _styleOverride,
        icon: iconWidget!,
        label: labelWidget,
      ),
      (true, null) => FilledButton.tonal(
        onPressed: effective,
        autofocus: autofocus,
        style: _styleOverride,
        child: labelWidget,
      ),
      (true, final Widget _) => FilledButton.tonalIcon(
        onPressed: effective,
        autofocus: autofocus,
        style: _styleOverride,
        icon: iconWidget!,
        label: labelWidget,
      ),
    };

    final Widget wrapped = expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;

    return tooltip == null
        ? wrapped
        : Tooltip(message: tooltip!, child: wrapped);
  }

  ButtonStyle? get _styleOverride => (visualDensity == null && padding == null)
      ? null
      : FilledButton.styleFrom(visualDensity: visualDensity, padding: padding);
}
