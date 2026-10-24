// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Тайл с переключателем UI-кита (обёртка [SwitchListTile]).
///
/// Материальный [SwitchListTile] разрешён только внутри `lib/uikit/`; в UI
/// приложения используйте [AppSwitchTile]. Весь тайл тапается (≥48dp),
/// переключатель во всю ширину — M3-дефолт.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.value,
    required this.title,
    this.onChanged,
    this.subtitle,
    this.secondary,
    this.contentPadding,
    this.dense = false,
  });

  /// Состояние переключателя.
  final bool value;

  /// `null` — тайл заблокирован.
  final ValueChanged<bool>? onChanged;

  /// Основная строка — обычно [AppText].
  final Widget title;

  /// Вторичная строка — обычно [AppText].
  final Widget? subtitle;

  /// Виджет на противоположной от переключателя стороне
  /// (иконка, бейдж-иконка тега).
  final Widget? secondary;

  final EdgeInsetsGeometry? contentPadding;

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      contentPadding: contentPadding,
      dense: dense,
    );
  }
}

/// Тайл с чекбоксом UI-кита (обёртка [CheckboxListTile]).
///
/// Материальный [CheckboxListTile] разрешён только внутри `lib/uikit/`;
/// для мультивыбора (список с чекбоксами слева) — [AppCheckboxTile].
class AppCheckboxTile extends StatelessWidget {
  const AppCheckboxTile({
    super.key,
    required this.value,
    required this.title,
    this.onChanged,
    this.subtitle,
    this.secondary,
    this.controlAffinity = ListTileControlAffinity.trailing,
    this.contentPadding,
    this.dense = false,
  });

  /// Состояние чекбокса.
  final bool value;

  /// `null` — тайл заблокирован; тип — M3-сигнатура `CheckboxListTile`
  /// (`ValueChanged<bool?>?`).
  final ValueChanged<bool?>? onChanged;

  /// Основная строка — обычно [AppText].
  final Widget title;

  /// Вторичная строка — обычно [AppText].
  final Widget? subtitle;

  /// Виджет на противоположной от чекбокса стороне.
  final Widget? secondary;

  /// Сторона чекбокса: `leading` — слева (предупреждения тренировки).
  final ListTileControlAffinity controlAffinity;

  final EdgeInsetsGeometry? contentPadding;

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      controlAffinity: controlAffinity,
      contentPadding: contentPadding,
      dense: dense,
    );
  }
}
