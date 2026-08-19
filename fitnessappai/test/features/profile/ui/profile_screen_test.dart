import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/body_measurement.dart';
import 'package:fitnessappai/features/profile/data/body_measurement_repository.dart';
import 'package:fitnessappai/features/profile/domain/body_metric.dart';
import 'package:fitnessappai/features/profile/ui/measurement_form_screen.dart';
import 'package:fitnessappai/features/profile/ui/profile_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late BodyMeasurementRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = BodyMeasurementRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  BodyMeasurement measurement({
    DateTime? date,
    double? weightKg,
    double? heightCm,
    double? waistCm,
  }) => BodyMeasurement(
    date: date ?? DateTime(2026, 8, 1),
    weightKg: weightKg,
    heightCm: heightCm,
    waistCm: waistCm,
  );

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              ProfileScreen(measurementRepository: repo),
        ),
        GoRoute(
          path: '/measurements/new',
          builder: (context, state) =>
              MeasurementFormScreen(measurementRepository: repo),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) =>
              const Scaffold(body: Text('SETTINGS_SCREEN')),
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

  testWidgets('пустое состояние показывает сообщение', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Пока нет замеров тела'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Противопоказания'), findsOneWidget);
  });

  testWidgets('форма добавляет замер', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Добавить замер'));
    await tester.pumpAndSettle();

    expect(find.text('Новый замер'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Вес'), '82');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    final date = DateFormat('d MMMM yyyy', 'ru').format(DateTime.now());
    expect(find.text('Новый замер'), findsNothing);
    expect(find.text(date), findsOneWidget);
    expect(find.text('82 кг'), findsWidgets);
    expect(await repo.getAll(), hasLength(1));
  });

  testWidgets('форма отклоняет нечисловое значение', (tester) async {
    await pumpProfile(tester);
    await tester.tap(find.text('Добавить замер'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Вес'), 'abc');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Введите число'), findsOneWidget);
    expect(await repo.getAll(), isEmpty);
  });

  testWidgets('выбор метрики меняет Dropdown и график', (tester) async {
    await repo.add(
      measurement(date: DateTime(2026, 8, 1), weightKg: 84, heightCm: 180),
    );
    await repo.add(
      measurement(date: DateTime(2026, 8, 5), weightKg: 82, heightCm: 179),
    );
    await repo.add(
      measurement(date: DateTime(2026, 8, 10), weightKg: 81, heightCm: 180),
    );

    await pumpProfile(tester);

    expect(find.byType(LineChart), findsOneWidget);
    expect(_chartYs(tester), [84, 82, 81]);

    await tester.tap(find.byType(DropdownButton<BodyMetric>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Рост').last);
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<BodyMetric>>(
      find.byType(DropdownButton<BodyMetric>),
    );
    expect(dropdown.value, BodyMetric.height);
    expect(_chartYs(tester), [180, 179, 180]);
  });

  testWidgets('удаление замера с подтверждением', (tester) async {
    await repo.add(measurement(weightKg: 80));

    await pumpProfile(tester);

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Удалить замер?'), findsOneWidget);
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('Пока нет замеров тела'), findsOneWidget);
    expect(await repo.getAll(), isEmpty);
  });

  testWidgets('отмена удаления сохраняет замер', (tester) async {
    await repo.add(measurement(weightKg: 80));

    await pumpProfile(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(await repo.getAll(), hasLength(1));
    expect(find.text('80 кг'), findsWidgets);
  });

  testWidgets('фильтр по году: по умолчанию выбран текущий год', (
    tester,
  ) async {
    final currentYear = DateTime.now().year;
    await repo.add(
      measurement(date: DateTime(currentYear - 1, 6, 1), weightKg: 80),
    );
    await repo.add(
      measurement(date: DateTime(currentYear, 8, 1), weightKg: 82),
    );

    await pumpProfile(tester);

    final dropdown = tester.widget<DropdownButton<int>>(
      find.byType(DropdownButton<int>),
    );
    expect(dropdown.value, currentYear);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('фильтр «Все годы» показывает замеры обоих годов', (
    tester,
  ) async {
    final currentYear = DateTime.now().year;
    await repo.add(
      measurement(date: DateTime(currentYear - 1, 6, 1), weightKg: 80),
    );
    await repo.add(
      measurement(date: DateTime(currentYear, 8, 1), weightKg: 82),
    );

    await pumpProfile(tester);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Все годы').last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
  });
}

List<double> _chartYs(WidgetTester tester) {
  final chart = tester.widget<LineChart>(find.byType(LineChart));
  final spots = chart.data.lineBarsData.first.spots;
  return [for (final spot in spots) spot.y];
}
