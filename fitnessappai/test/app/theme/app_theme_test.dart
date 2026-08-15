import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/app/theme/theme_controller.dart';
import 'package:fitnessappai/app/theme/theme_settings_repository.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/main.dart';

import '../../helpers/test_services.dart';

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

    test('используется seed-цвет', () {
      final ThemeData theme = AppTheme.dark();
      final ColorScheme expected = ColorScheme.fromSeed(
        seedColor: AppTheme.seedColor,
        brightness: Brightness.dark,
      );

      expect(theme.colorScheme.primary, expected.primary);
      expect(theme.colorScheme.secondary, expected.secondary);
      expect(theme.colorScheme.surface, expected.surface);
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
  });

  group('FitnessAppAi', () {
    testWidgets('приложение использует тёмную тему', (
      WidgetTester tester,
    ) async {
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

      await tester.pumpWidget(FitnessAppAi(themeController: controller));

      controller.setMode(ThemeMode.light);
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(NavigationBar));
      expect(Theme.of(context).brightness, Brightness.light);
    });
  });
}
