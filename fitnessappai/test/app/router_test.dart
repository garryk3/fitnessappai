import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/router.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

import '../helpers/test_services.dart';

void main() {
  setUp(registerTestServices);

  Widget buildApp(GoRouter router) {
    return MaterialApp.router(
      theme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      routerConfig: router,
    );
  }

  group('AppRouter', () {
    testWidgets('вкладки переключаются', (WidgetTester tester) async {
      final GoRouter router = AppRouter.create();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      expect(find.text('Нет программ'), findsOneWidget);

      await tester.tap(find.text('Упражнения'));
      await tester.pumpAndSettle();

      expect(find.text('Поиск упражнений'), findsOneWidget);

      await tester.tap(find.text('Программы'));
      await tester.pumpAndSettle();

      expect(find.text('Список программ пуст'), findsOneWidget);

      await tester.tap(find.text('План'));
      await tester.pumpAndSettle();

      expect(find.text('Нет запланированных тренировок'), findsOneWidget);
    });

    testWidgets('deep-link на роут истории открывает экран', (
      WidgetTester tester,
    ) async {
      final GoRouter router = AppRouter.create();
      await tester.pumpWidget(buildApp(router));

      router.go('/history');
      await tester.pumpAndSettle();

      expect(find.text('Пока нет тренировок'), findsOneWidget);
    });

    testWidgets('deep-link на динамику упражнения открывает экран', (
      WidgetTester tester,
    ) async {
      final GoRouter router = AppRouter.create();
      await tester.pumpWidget(buildApp(router));

      router.go('/progress/exercise/42');
      await tester.pumpAndSettle();

      expect(find.text('Упражнение не найдено'), findsOneWidget);
    });

    testWidgets('deep-link на детали дня открывает экран', (
      WidgetTester tester,
    ) async {
      final GoRouter router = AppRouter.create();
      await tester.pumpWidget(buildApp(router));

      router.go('/progress/day?start=0&end=0');
      await tester.pumpAndSettle();

      expect(find.text('Нет тренировок за этот день'), findsOneWidget);
    });

    testWidgets('deep-link с параметром открывает экран упражнения', (
      WidgetTester tester,
    ) async {
      final GoRouter router = AppRouter.create();
      await tester.pumpWidget(buildApp(router));

      router.go('/exercises/42');
      await tester.pumpAndSettle();

      expect(find.text('Упражнение не найдено'), findsOneWidget);
    });

    testWidgets('deep-link на настройки открывает экран', (
      WidgetTester tester,
    ) async {
      final GoRouter router = AppRouter.create();
      await tester.pumpWidget(buildApp(router));

      router.go('/settings');
      await tester.pumpAndSettle();

      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Экспортировать БД'), findsOneWidget);
    });

    testWidgets('неизвестный маршрут показывает 404', (
      WidgetTester tester,
    ) async {
      final GoRouter router = AppRouter.create();
      await tester.pumpWidget(buildApp(router));

      router.go('/nonexistent');
      await tester.pumpAndSettle();

      expect(find.text('404'), findsOneWidget);
      expect(find.text('Страница не найдена'), findsOneWidget);
    });
  });
}
