// ignore_for_file: type=lint
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/sound/sound_service.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/features/workout/ui/workout_run_screen.dart';
import 'package:fitnessappai/features/workout/ui/workout_warmup_screen.dart';
import 'package:fitnessappai/app/localization_delegates.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/app_scaffold.dart';

class _FakeWakelock implements WakelockService {
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<void> enable() async {
    enableCalls++;
  }

  @override
  Future<void> disable() async {
    disableCalls++;
  }
}

void main() {
  late _FakeWakelock wakelock;

  Future<void> pumpWarmup(
    WidgetTester tester, {
    required int seconds,
    SoundService? soundService,
  }) async {
    locator.reset();
    wakelock = _FakeWakelock();
    locator.registerLazySingleton<WakelockService>(() => wakelock);
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
        localizationsDelegates: appLocalizationsDelegates,
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
    // 61.9: дубль информации удалён — «осталось N с» больше не рисуется.
    expect(find.textContaining('осталось'), findsNothing);
    expect(find.text('Пропустить'), findsOneWidget);
  });

  testWidgets('66.5: BACK на разминке спрашивает подтверждение', (
    tester,
  ) async {
    locator.reset();
    wakelock = _FakeWakelock();
    locator.registerLazySingleton<WakelockService>(() => wakelock);
    final router = GoRouter(
      initialLocation: '/prepare',
      routes: [
        GoRoute(
          path: '/prepare',
          builder: (context, state) =>
              const Scaffold(body: Text('prepare-screen')),
        ),
        GoRoute(
          path: '/workout/warmup',
          builder: (context, state) => WorkoutWarmupScreen(
            programDayId: 1,
            warmupSeconds: 30,
            variant: WorkoutVariant.main,
            soundService: StubSoundService(),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark(),
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();
    router.push('/workout/warmup?seconds=30');
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Выйти из разминки?'), findsOneWidget);

    // «Отмена» остаётся на разминке.
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Разминка'), findsOneWidget);

    // «Выйти» возвращает на подготовку.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();
    expect(find.text('Разминка'), findsNothing);
    expect(find.text('prepare-screen'), findsOneWidget);
  });

  testWidgets('61.9: таймер-карточка вертикально центрирована в теле', (
    tester,
  ) async {
    await pumpWarmup(tester, seconds: 30);

    // Центр карточки совпадает с центром тела экрана (без шапки) в пределах
    // допуска: содержимое центрируется, а не прижато к краю.
    final cardCenter = tester.getCenter(find.text('00:30'));
    final screenHeight = tester.getSize(find.byType(AppScaffold)).height;
    expect((cardCenter.dy - screenHeight / 2).abs(), lessThan(24));
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

  testWidgets(
    '«Пропустить» отменяет таймер: звук завершения не сработает позже (58.1)',
    (tester) async {
      final sound = StubSoundService();
      await pumpWarmup(tester, seconds: 5, soundService: sound);

      await tester.tap(find.text('Пропустить'));
      await tester.pumpAndSettle();
      expect(find.text('run-screen'), findsOneWidget);

      // Экран разминки остаётся mounted (push поверх); таймет как был активен
      // до фикса — дотикал бы и сыграл завершение здесь (дефект 58.1).
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(sound.completionCalls, 0);
    },
  );

  testWidgets(
    'wake lock включается при старте разминки и выключается при выходе',
    (tester) async {
      await pumpWarmup(tester, seconds: 30);

      expect(wakelock.enableCalls, 1);
      expect(wakelock.disableCalls, 0);

      await tester.pumpWidget(const SizedBox());
      expect(wakelock.disableCalls, 1);
    },
  );
}
