// ignore_for_file: type=lint
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';
import 'package:fitnessappai/app/theme/theme_controller.dart';
import 'package:fitnessappai/app/theme/theme_settings_repository.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/main.dart';

import '../../helpers/test_services.dart';

/// WCAG-контраст двух цветов (формула из раздела 7 DESIGN.md).
/// `Color.r/g/b` в Flutter ≥3.27 — дроби 0..1.
double _contrastRatio(Color a, Color b) {
  double luminanceOf(Color color) {
    double channel(double c) {
      return c <= 0.04045
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  final double l1 = luminanceOf(a);
  final double l2 = luminanceOf(b);
  final double lighter = math.max(l1, l2);
  final double darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  setUp(registerTestServices);

  group('AppTheme', () {
    test('dark возвращает тему с brightness=dark', () {
      final ThemeData theme = AppTheme.dark();

      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('light возвращает тему с brightness=light', () {
      final ThemeData theme = AppTheme.light();

      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('используется seed-цвет (акценты)', () {
      final ThemeData theme = AppTheme.dark();
      final ColorScheme expected = ColorScheme.fromSeed(
        seedColor: AppTheme.seedColor,
        brightness: Brightness.dark,
      );

      expect(theme.colorScheme.primary, expected.primary);
      expect(theme.colorScheme.secondary, expected.secondary);
      expect(theme.colorScheme.tertiary, expected.tertiary);
      expect(theme.colorScheme.error, expected.error);
    });

    test('тёмная тема: near-black поверхности слоями (54.1)', () {
      final ColorScheme scheme = AppTheme.dark().colorScheme;

      expect(scheme.surface, const Color(0xFF101018));
      expect(scheme.surfaceContainerLowest, const Color(0xFF0B0B12));
      expect(scheme.surfaceContainerLow, const Color(0xFF17171F));
      expect(scheme.surfaceContainer, const Color(0xFF1C1C25));
      expect(scheme.surfaceContainerHigh, const Color(0xFF232330));
      expect(scheme.surfaceContainerHighest, const Color(0xFF2D2D3C));

      // Слои строго светлеют от lowest к highest (не «плоский» фон).
      expect(
        scheme.surfaceContainerLowest.computeLuminance(),
        lessThan(scheme.surface.computeLuminance()),
      );
      expect(
        scheme.surface.computeLuminance(),
        lessThan(scheme.surfaceContainerLow.computeLuminance()),
      );
      expect(
        scheme.surfaceContainerLow.computeLuminance(),
        lessThan(scheme.surfaceContainer.computeLuminance()),
      );
      expect(
        scheme.surfaceContainer.computeLuminance(),
        lessThan(scheme.surfaceContainerHigh.computeLuminance()),
      );
      expect(
        scheme.surfaceContainerHigh.computeLuminance(),
        lessThan(scheme.surfaceContainerHighest.computeLuminance()),
      );
    });

    test('светлая тема: поверхности остаются M3 из seed (54.1)', () {
      final ColorScheme light = AppTheme.light().colorScheme;
      final ColorScheme expected = ColorScheme.fromSeed(
        seedColor: AppTheme.seedColor,
        brightness: Brightness.light,
      );

      expect(light.surface, expected.surface);
      expect(light.surfaceContainerLow, expected.surfaceContainerLow);
      expect(light.surfaceContainer, expected.surfaceContainer);
      expect(light.surfaceContainerHigh, expected.surfaceContainerHigh);
      expect(light.surfaceContainerHighest, expected.surfaceContainerHighest);
    });

    test('обе темы: текстовые пары держат AAA (7:1)', () {
      for (final ThemeData theme in [AppTheme.light(), AppTheme.dark()]) {
        final ColorScheme scheme = theme.colorScheme;
        final List<Color> surfaces = [
          scheme.surface,
          scheme.surfaceContainerLow,
          scheme.surfaceContainer,
          scheme.surfaceContainerHigh,
          scheme.surfaceContainerHighest,
        ];
        for (final Color surface in surfaces) {
          expect(
            _contrastRatio(scheme.onSurface, surface),
            greaterThanOrEqualTo(7.0),
            reason: 'onSurface/$surface',
          );
          expect(
            _contrastRatio(scheme.onSurfaceVariant, surface),
            greaterThanOrEqualTo(4.5),
            reason: 'onSurfaceVariant/$surface',
          );
        }
        // Неон-обводки/бордеры (UI-графика, критерий 1.4.11 ≥3:1) —
        // заявлено в DESIGN.md §11, закрепляем автотестом.
        for (final Color surface in surfaces) {
          expect(
            _contrastRatio(scheme.outline, surface),
            greaterThanOrEqualTo(3.0),
            reason: 'outline/$surface',
          );
        }
      }
    });

    test('заданы стили ключевых компонентов', () {
      final ThemeData theme = AppTheme.dark();

      expect(theme.navigationBarTheme, isNotNull);
      expect(theme.navigationRailTheme, isNotNull);
      expect(theme.cardTheme, isNotNull);
      expect(theme.filledButtonTheme, isNotNull);
      expect(theme.segmentedButtonTheme, isNotNull);
      expect(theme.searchBarTheme, isNotNull);
      expect(theme.dialogTheme, isNotNull);
    });

    test('54.2: бар/rail — pill-индикатор на приподнятой поверхности', () {
      for (final ThemeData theme in [AppTheme.light(), AppTheme.dark()]) {
        final ColorScheme scheme = theme.colorScheme;

        final bar = theme.navigationBarTheme;
        expect(bar.indicatorColor, scheme.surfaceContainerHighest);
        final barShape = bar.indicatorShape! as RoundedRectangleBorder;
        expect(
          (barShape.borderRadius as BorderRadius).topLeft.x,
          AppRadii.pill,
        );
        // Плоский бар без тени (тональная элевация).
        expect(bar.elevation, 0);
        // Неон-акцент: иконка выбранной вкладки — primary.
        final selectedIcon = bar.iconTheme!.resolve(const {
          WidgetState.selected,
        });
        expect(selectedIcon!.color, scheme.primary);
        final idleIcon = bar.iconTheme!.resolve(const {});
        expect(idleIcon!.color, scheme.onSurfaceVariant);

        final rail = theme.navigationRailTheme;
        expect(rail.indicatorColor, scheme.surfaceContainerHighest);
        final railShape = rail.indicatorShape! as RoundedRectangleBorder;
        expect(
          (railShape.borderRadius as BorderRadius).topLeft.x,
          AppRadii.pill,
        );
        expect(rail.selectedIconTheme!.color, scheme.primary);
        expect(rail.unselectedIconTheme!.color, scheme.onSurfaceVariant);
      }
    });

    test('54.2: шапка — крупные заголовки, без тинта', () {
      for (final ThemeData theme in [AppTheme.light(), AppTheme.dark()]) {
        final appBar = theme.appBarTheme;
        // Заголовки (headlineMedium/displaySmall) задаёт AppTopBar из
        // контекстной темы — appBarTheme.titleTextStyle остаётся пустым
        // (standalone textTheme ненадёжен без локализации MaterialApp).
        expect(appBar.titleTextStyle, isNull);
        expect(appBar.backgroundColor, theme.colorScheme.surface);
        expect(appBar.surfaceTintColor, Colors.transparent);
        expect(appBar.scrolledUnderElevation, 0);
      }
    });

    test('54.2: выбранный пункт списка — приподнятая поверхность и pill', () {
      for (final ThemeData theme in [AppTheme.light(), AppTheme.dark()]) {
        expect(
          theme.listTileTheme.selectedTileColor,
          theme.colorScheme.surfaceContainerHighest,
        );
        // Та же pill-форма, что у индикатора активной вкладки бара/rail-а.
        final shape = theme.listTileTheme.shape;
        expect(shape, isA<RoundedRectangleBorder>());
        expect(
          (shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(AppRadii.pill),
        );
      }
    });
  });

  group('FitnessAppAi', () {
    testWidgets('приложение использует тёмную тему', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(480, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const FitnessAppAi());

      final BuildContext context = tester.element(find.byType(NavigationBar));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('смена темы меняет brightness приложения', (
      WidgetTester tester,
    ) async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final controller = ThemeController(ThemeSettingsRepository(db));

      // Бар навигации рендерится только на узких экранах (<600 lsV); иначе — rail.
      tester.view.physicalSize = const Size(480, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(FitnessAppAi(themeController: controller));

      controller.setMode(ThemeMode.light);
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(NavigationBar));
      expect(Theme.of(context).brightness, Brightness.light);
    });

    testWidgets('смена темы не сбрасывает маршрут на главный экран', (
      WidgetTester tester,
    ) async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final controller = ThemeController(ThemeSettingsRepository(db));

      // Бар навигации рендерится только на узких экранах (<600 lsV); иначе — rail.
      tester.view.physicalSize = const Size(480, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(FitnessAppAi(themeController: controller));
      await tester.pumpAndSettle();

      GoRouter.of(tester.element(find.byType(NavigationBar))).go('/settings');
      await tester.pumpAndSettle();

      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Синхронизация'), findsOneWidget);

      controller.setMode(ThemeMode.light);
      await tester.pumpAndSettle();

      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Синхронизация'), findsOneWidget);
      expect(find.text('Нет программ'), findsNothing);
    });
  });
}
