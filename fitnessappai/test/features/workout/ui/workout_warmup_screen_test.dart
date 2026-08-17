import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/workout/ui/workout_warmup_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  Future<void> pumpWarmup(WidgetTester tester, {required int seconds}) async {
    final router = GoRouter(
      initialLocation: '/workout/warmup?seconds=$seconds',
      routes: [
        GoRoute(
          path: '/workout/warmup',
          builder: (context, state) => WorkoutWarmupScreen(
            programDayId: 1,
            warmupSeconds: seconds,
            variant: WorkoutVariant.main,
          ),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) => const Scaffold(body: Text('run-screen')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark(),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('показывает обратный отсчёт и кнопку «Пропустить»', (
    tester,
  ) async {
    await pumpWarmup(tester, seconds: 5);

    expect(find.text('Разминка'), findsOneWidget);
    expect(find.text('00:05'), findsOneWidget);
    expect(find.text('осталось 5 с'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);
  });

  testWidgets('«Пропустить» переходит к тренировке', (tester) async {
    await pumpWarmup(tester, seconds: 30);

    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();

    expect(find.text('run-screen'), findsOneWidget);
  });

  testWidgets('по завершении отсчёта переходит к тренировке', (tester) async {
    await pumpWarmup(tester, seconds: 3);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:02'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('run-screen'), findsOneWidget);
  });
}
