// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Зона нажатия UI-кита.
///
/// Материальный [InkWell] разрешён только внутри `lib/uikit/`; в UI приложения
/// используйте [AppInkWell] (иначе падает правило `ban_inkwell_widget`).
/// Для карточки/строки со всем оформлением предпочитайте [AppCard]/[AppTile].
class AppInkWell extends StatelessWidget {
  const AppInkWell({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTap,
    this.borderRadius,
    this.customBorder,
    this.radius,
    this.mouseCursor,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.splashFactory,
    this.canRequestFocus,
    this.autofocus = false,
    this.focusNode,
    this.excludeFromSemantics = false,
  });

  final Widget child;
  final GestureTapCallback? onTap;
  final GestureTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final GestureTapCallback? onSecondaryTap;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final double? radius;
  final MouseCursor? mouseCursor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final InteractiveInkFeatureFactory? splashFactory;
  final bool? canRequestFocus;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      onSecondaryTap: onSecondaryTap,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      mouseCursor: mouseCursor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      splashFactory: splashFactory,
      canRequestFocus: canRequestFocus ?? true,
      autofocus: autofocus,
      focusNode: focusNode,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    );
  }
}
