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

      expect(find.text('Поиск упражнений'), findsOneWidget);

      await tester.tap(find.text('Программы'));
      await tester.pumpAndSettle();

      expect(find.text('Раздел «Программы» в разработке'), findsOneWidget);

      await tester.tap(find.text('План'));
      await tester.pumpAndSettle();

      expect(find.text('Раздел «План» в разработке'), findsOneWidget);
    });

    testWidgets('deep-link на роут истории открывает экран', (
      WidgetTester tester,
    ) async {
      final GoRouter router = AppRouter.create();
      await tester.pumpWidget(buildApp(router));

      router.go('/history');
      await tester.pumpAndSettle();

      expect(find.text('Раздел «История» в разработке'), findsOneWidget);
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
