// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Переключатель UI-кита (обёртка [Switch]).
///
/// Материальный [Switch] разрешён только внутри `lib/uikit/`; в UI
/// приложения используйте [AppSwitch]. Для самостоятельной строки с
/// заголовком — [AppSwitchTile] (тап на весь тайл).
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  /// Состояние переключателя.
  final bool value;

  /// `null` — заблокирован.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(value: value, onChanged: onChanged);
  }
}

/// Чекбокс UI-кита (обёртка [Checkbox]).
///
/// Материальный [Checkbox] разрешён только внутри `lib/uikit/`; в UI
/// приложения используйте [AppCheckbox]. Для строки с заголовком —
/// тег-бейджи через `AppSwitchTile` или [AppCheckboxTile].
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.value, this.onChanged});

  /// Состояние чекбокса.
  final bool value;

  /// `null` — заблокирован; тип — M3-сигнатура `Checkbox`
  /// (`ValueChanged<bool?>?` — для совместимости, значение не tristate).
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Checkbox(value: value, onChanged: onChanged);
  }
}
