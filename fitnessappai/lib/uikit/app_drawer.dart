// ignore_for_file: type=lint
import 'package:flutter/material.dart';

/// Drawer UI-кита (обёртка [Drawer]).
///
/// Материальный [Drawer] разрешён только внутри `lib/uikit/`; в UI
/// приложения используйте [AppDrawer] (адаптивная навигация 54.2).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.child});

  /// Содержимое панели (ширина — M3-дефолт).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Drawer(child: child);
  }
}
