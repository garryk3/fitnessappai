import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/main.dart';

import '../../helpers/test_services.dart';

void main() {
  setUp(registerTestServices);

  group('AppTheme', () {
    test('dark возвращает тему с brightness=dark', () {
      final ThemeData theme = AppTheme.dark();

      expect(theme.colorScheme.brightness, Brightness.dark);
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
  });
}
