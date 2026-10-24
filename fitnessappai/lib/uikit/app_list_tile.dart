// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Строка-тайл UI-кита (обёртка [ListTile]).
///
/// Материальный [ListTile] разрешён только внутри `lib/uikit/`; в UI
/// приложения используйте [AppListTile]. Оформление задаётся темой
/// (`listTileTheme`, этап 54.2: selected — pill на `surfaceContainerHighest`).
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.selectedTileColor,
    this.enabled = true,
    this.dense = false,
    this.contentPadding,
  });

  /// Виджет слева (иконка, миниатюра, чекбокс выбора).
  final Widget? leading;

  /// Основная строка — обычно [AppText].
  final Widget? title;

  /// Вторичная строка — обычно [AppText].
  final Widget? subtitle;

  /// Виджет справа.
  final Widget? trailing;

  /// `null` — тайл неактивен.
  final VoidCallback? onTap;

  /// Подсветка активного пункта (тема задаёт pill-фон).
  final bool selected;

  /// Переопределение цвета выбранного пункта.
  final Color? selectedTileColor;

  /// `false` — тексты приглушены.
  final bool enabled;

  final bool dense;

  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      selected: selected,
      selectedTileColor: selectedTileColor,
      enabled: enabled,
      dense: dense,
      contentPadding: contentPadding,
    );
  }
}
