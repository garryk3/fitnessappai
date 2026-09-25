import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/router.dart';
import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/features/workout/data/wakelock_banner_repository.dart';
import 'package:fitnessappai/features/workout/domain/workout_checkpoint.dart';
import 'package:fitnessappai/features/workout/domain/workout_foreground_service.dart';
import 'package:fitnessappai/features/workout/ui/workout_run_screen.dart';
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
      // 43.2: история — ветка shell: нижний бар с вкладками на месте.
      expect(find.byType(NavigationBar), findsOneWidget);
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
      expect(find.text('Поделиться'), findsOneWidget);
      expect(find.text('Сохранить в файлы'), findsOneWidget);
      // 43.5: настройки — ветка shell с меню: нижний бар на месте.
      expect(find.byType(NavigationBar), findsOneWidget);
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

    testWidgets(
      'восстановление тренировки: redirect одноразовый, выход не застревает',
      (WidgetTester tester) async {
        final db = locator.get<AppDatabase>();
        locator.registerLazySingleton<WakelockService>(
          () => _StubWakelockService(),
        );
        locator.registerLazySingleton<WorkoutForegroundService>(
          () => _StubForegroundService(),
        );
        locator.registerLazySingleton<WakelockBannerRepository>(
          () => WakelockBannerRepository(db),
        );

        final checkpoint = WorkoutCheckpoint(
          programDayId: 999,
          exerciseIndex: 0,
          currentSet: 1,
          completedSets: 0,
          resultsJson: '[]',
          startedAt: DateTime(2026, 9, 25),
          programName: 'Тест',
          dayIndex: 0,
        );
        final GoRouter router = AppRouter.create(
          initialCheckpoint: checkpoint,
        );
        await tester.pumpWidget(buildApp(router));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Первая навигация перенаправляется на восстановление тренировки.
        expect(router.state.matchedLocation, '/workout/run');

        // Переход на главную после обработки восстановленного экрана
        // не должен уводить обратно на пустую тренировку (TC-058).
        router.go('/home');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(router.state.matchedLocation, '/home');
      },
    );
  });
}

class _StubWakelockService implements WakelockService {
  @override
  bool get isEnabled => true;

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

class _StubForegroundService implements WorkoutForegroundService {
  @override
  Future<void> start({required String title, required String text}) async {}

  @override
  Future<void> update({required String title, required String text}) async {}

  @override
  Future<void> stop() async {}
}
