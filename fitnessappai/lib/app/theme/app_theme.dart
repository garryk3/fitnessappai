// ignore_for_file: type=lint
import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Material 3 темы приложения: светлая и тёмная.
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF7E57C2);

  /// Светлая тема.
  static ThemeData light() => _build(Brightness.light);

  /// Тёмная тема.
  static ThemeData dark() => _build(Brightness.dark);

  /// Near-black поверхности тёмной темы (редизайн 54, DESIGN.md §11).
  ///
  /// Сэмплированы из образцов владельца (`templates/`, доминантный фон
  /// `#101018`): фон глубже M3 `#151218`, контейнеры слоями светлеют.
  /// Контрастные пары с `onSurface`/`onSurfaceVariant`/`outline` проверены
  /// и превышают M3-значения (см. §11) — тест `app_theme_test.dart`.
  static const Color _darkSurfaceLowest = Color(0xFF0B0B12);
  static const Color _darkSurface = Color(0xFF101018);
  static const Color _darkSurfaceLow = Color(0xFF17171F);
  static const Color _darkSurfaceContainer = Color(0xFF1C1C25);
  static const Color _darkSurfaceHigh = Color(0xFF232330);
  static const Color _darkSurfaceHighest = Color(0xFF2D2D3C);

  static ThemeData _build(Brightness brightness) {
    ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    if (brightness == Brightness.dark) {
      colorScheme = colorScheme.copyWith(
        surfaceContainerLowest: _darkSurfaceLowest,
        surface: _darkSurface,
        surfaceContainerLow: _darkSurfaceLow,
        surfaceContainer: _darkSurfaceContainer,
        surfaceContainerHigh: _darkSurfaceHigh,
        surfaceContainerHighest: _darkSurfaceHighest,
      );
    }
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        // Редизайн 54 (§11): шапка «сливается» со scaffold — без тинта и
        // скролл-поднятия. Крупные заголовки задаёт AppTopBar из контекстной
        // темы (displaySmall/headlineMedium) — appBarTheme.titleTextStyle
        // здесь не заполняется (standalone textTheme ненадёжен без
        // локализации MaterialApp).
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      // Редизайн 54 (§11): активная вкладка/rail — pill-индикатор на
      // приподнятой поверхности + неон-акцент (primary) на иконке.
      // Плоский бар без теней (тональная элевация).
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.surfaceContainerHighest,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.surfaceContainerHighest,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
      // Редизайн 54: выбранный пункт списка (drawer-меню и т.п.) — та же
      // приподнятая поверхность, что у индикатора бара/rail-а, и тот же
      // pill-язык формы (stadium — как у индикатора активной вкладки).
      listTileTheme: ListTileThemeData(
        selectedTileColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(2),
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHigh,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xxl),
        ),
      ),
    );
  }
}
