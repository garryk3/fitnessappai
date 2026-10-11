// ignore_for_file: type=lint
import 'package:flutter/material.dart';

import 'package:fitnessappai/uikit/app_text.dart';

/// Верхняя панель UI-кита — единственная точка использования Material [AppBar].
///
/// Материальный [AppBar] разрешён только внутри `lib/uikit/`; в UI приложения
/// используйте [AppTopBar] (иначе падает правило `ban_appbar_widget`).
///
/// Заголовок можно задать строкой [title] (тогда он рендерится через [AppText]
/// со стилем из `AppBarTheme`) или произвольным виджетом [titleWidget].
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.backgroundColor,
    this.foregroundColor,
    this.surfaceTintColor,
    this.shadowColor,
    this.centerTitle,
    this.toolbarHeight,
    this.toolbarOpacity = 1.0,
    this.bottomOpacity = 1.0,
  });

  /// Текстовый заголовок.
  final String? title;

  /// Заголовок-виджет (приоритетнее [title]).
  final Widget? titleWidget;

  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final double? scrolledUnderElevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? surfaceTintColor;
  final Color? shadowColor;
  final bool? centerTitle;
  final double? toolbarHeight;
  final double toolbarOpacity;
  final double bottomOpacity;

  // Высота зеркалит поведение Flutter `AppBar`: учитывается только явный
  // `toolbarHeight` (тема в `preferredSize` не читается — так же, как в SDK).
  @override
  Size get preferredSize => Size.fromHeight(
    toolbarHeight ?? kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle =
        theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge;

    return AppBar(
      title:
          titleWidget ??
          (title == null ? null : AppText(title!, style: titleStyle)),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      surfaceTintColor: surfaceTintColor,
      shadowColor: shadowColor,
      centerTitle: centerTitle,
      toolbarHeight: toolbarHeight,
      toolbarOpacity: toolbarOpacity,
      bottomOpacity: bottomOpacity,
    );
  }
}
