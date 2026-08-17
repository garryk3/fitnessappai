import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/features/workout/ui/workout_warmup_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  Future<void> pumpWarmup(
    WidgetTester tester, {
    required int seconds,
    SoundService? soundService,
  }) async {
    final router = GoRouter(
      initialLocation: '/workout/warmup?seconds=$seconds',
      routes: [
        GoRoute(
          path: '/workout/warmup',
          builder: (context, state) => WorkoutWarmupScreen(
            programDayId: 1,
            warmupSeconds: seconds,
            variant: WorkoutVariant.main,
            soundService: soundService ?? StubSoundService(),
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

  testWidgets('по завершении отсчёта играет звуковой сигнал', (tester) async {
    final sound = StubSoundService();
    await pumpWarmup(tester, seconds: 2, soundService: sound);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(sound.completionCalls, 1);
  });

  testWidgets('«Пропустить» не играет звук', (tester) async {
    final sound = StubSoundService();
    await pumpWarmup(tester, seconds: 30, soundService: sound);

    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();

    expect(sound.completionCalls, 0);
  });
}
