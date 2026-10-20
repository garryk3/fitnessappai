// ignore_for_file: type=lint
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
import 'package:fitnessappai/features/profile/domain/bmi.dart';
import 'package:fitnessappai/features/profile/domain/body_metric.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/profile/ui/measurement_form_screen.dart';
import 'package:fitnessappai/features/profile/ui/profile_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

void main() {
  late AppDatabase db;
  late BodyMeasurementRepository repo;
  late UserProfileRepository profileRepo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = BodyMeasurementRepository(db);
    profileRepo = UserProfileRepository(db);
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
          builder: (context, state) => ProfileScreen(
            measurementRepository: repo,
            profileRepository: profileRepo,
          ),
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
    // FAB редизайна 54.9 — градиентная пилюля с Tooltip (byType
    // FloatingActionButton больше нет — контракт по тексту/тултипу).
    expect(find.byTooltip('Добавить замер'), findsOneWidget);
    expect(find.text('Противопоказания'), findsOneWidget);
  });

  testWidgets('редизайн 54.9: FAB — градиентная пилюля AppGlowContainer', (
    tester,
  ) async {
    await pumpProfile(tester);

    // Контракт «Добавить замер» — тултип (e2e тапает по тексту внутри
    // AppInkWell — предок текста, hit-test проходит).
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(AppGlowContainer), findsOneWidget);
    expect(find.byTooltip('Добавить замер'), findsOneWidget);
  });

  testWidgets('редизайн 54.9: чипы значений с иконками-бейджами', (
    tester,
  ) async {
    await repo.add(
      measurement(
        date: DateTime(2026, 8, 1),
        weightKg: 80,
        heightCm: 178,
        waistCm: 84,
      ),
    );
    await pumpProfile(tester);

    expect(find.text('Текущие значения'), findsOneWidget);
    expect(find.byIcon(Icons.height), findsOneWidget);
    // Чип «Вес» + бейдж строки истории (вес известен).
    expect(find.byIcon(Icons.monitor_weight_outlined), findsNWidgets(2));
    // Восемь чипов обхватов — линейка (в истории — весы).
    expect(find.byIcon(Icons.straighten_outlined), findsNWidgets(8));
  });

  testWidgets('редизайн 54.9: форма — секция обхватов и градиентные карточки', (
    tester,
  ) async {
    await pumpProfile(tester);
    await tester.tap(find.text('Добавить замер'));
    await tester.pumpAndSettle();

    expect(find.text('Обхваты (см)'), findsOneWidget);
    // Дата (без градиента) + рост + вес + 8 обхватов = 10 градиентных.
    final gradientCards = tester
        .widgetList<AppCard>(find.byType(AppCard))
        .where((card) => card.gradient != null)
        .toList();
    expect(gradientCards, hasLength(10));
    // Сетка 2 колонки: «Шея» и «Грудь» — один ряд, разные колонки.
    final neck = tester.getRect(find.widgetWithText(AppCard, 'Шея'));
    final chest = tester.getRect(find.widgetWithText(AppCard, 'Грудь'));
    expect(neck.top, closeTo(chest.top, 1));
    expect(neck.left, lessThan(chest.left));
    expect(neck.right, lessThanOrEqualTo(chest.left));
  });

  testWidgets(
    'редизайн 54.9: форма на самом узком экране (320dp) без overflow',
    (tester) async {
      await pumpProfile(tester);
      // 320dp — минимальная заявленная ширина; вьюпорт высокий, чтобы все
      // карточки обхватов построились и layout-исключения были видны.
      tester.view.physicalSize = const Size(320, 2400);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpAndSettle();

      await tester.tap(find.text('Добавить замер'));
      await tester.pumpAndSettle();

      expect(find.text('Обхваты (см)'), findsOneWidget);
      expect(find.byIcon(Icons.straighten_outlined), findsNWidgets(8));
      expect(tester.takeException(), isNull);
    },
  );

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

  testWidgets('график: подписи снизу не выходят за пределы блока (fitInside)', (
    tester,
  ) async {
    await repo.add(measurement(date: DateTime(2026, 8, 1), weightKg: 84));
    await repo.add(measurement(date: DateTime(2026, 8, 5), weightKg: 82));
    await repo.add(measurement(date: DateTime(2026, 8, 10), weightKg: 81));

    await pumpProfile(tester);

    expect(find.byType(LineChart), findsOneWidget);
    final titles = tester
        .widgetList<SideTitleWidget>(find.byType(SideTitleWidget))
        .toList();
    // Нижние подписи обёрнуты в SideTitleWidget с включённым fitInside,
    // чтобы последняя подпись не выходила за правый край графика.
    expect(titles, isNotEmpty);
    for (final title in titles) {
      expect(title.fitInside.enabled, isTrue);
    }
  });

  testWidgets('график: подпись «Сегодня» для замера текущего дня', (
    tester,
  ) async {
    await repo.add(measurement(date: DateTime.now(), weightKg: 80));

    await pumpProfile(tester);

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Сегодня'), findsWidgets);
  });

  testWidgets('график: дата замера в формате «д.мес» рядом с «Сегодня»', (
    tester,
  ) async {
    final past = DateTime.now().subtract(const Duration(days: 3));
    await repo.add(measurement(date: past, weightKg: 80));

    await pumpProfile(tester);

    final expected = DateFormat('d.M', 'ru').format(past);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text(expected), findsOneWidget);
    expect(find.text('Сегодня'), findsWidgets);
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

  testWidgets('история: до 10 замеров кнопка «Загрузить ещё» не показывается', (
    tester,
  ) async {
    for (var day = 1; day <= 10; day++) {
      await repo.add(
        measurement(date: DateTime(2026, 8, day), weightKg: 100.0 - day),
      );
    }

    await pumpProfile(tester);

    expect(find.byIcon(Icons.delete_outline), findsNWidgets(10));
    expect(find.text('Загрузить ещё'), findsNothing);
  });

  testWidgets(
    'история: после 10 замеров кнопка «Загрузить ещё» загружает остаток',
    (tester) async {
      for (var day = 1; day <= 13; day++) {
        await repo.add(
          measurement(date: DateTime(2026, 8, day), weightKg: 100.0 - day),
        );
      }

      await pumpProfile(tester);

      expect(find.byIcon(Icons.delete_outline), findsNWidgets(10));
      expect(find.text('Загрузить ещё'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Загрузить ещё'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Загрузить ещё'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsNWidgets(13));
      expect(find.text('Загрузить ещё'), findsNothing);
    },
  );

  testWidgets('история: свежий замер показывается первым (DESC)', (
    tester,
  ) async {
    await repo.add(
      measurement(date: DateTime(2026, 8, 1), weightKg: 82, heightCm: 180),
    );
    await repo.add(
      measurement(date: DateTime(2026, 8, 10), weightKg: 81, heightCm: 180),
    );

    await pumpProfile(tester);

    final latestDate = DateFormat(
      'd MMMM yyyy',
      'ru',
    ).format(DateTime(2026, 8, 10));
    final olderDate = DateFormat(
      'd MMMM yyyy',
      'ru',
    ).format(DateTime(2026, 8, 1));
    final latestY = tester.getTopLeft(find.text(latestDate)).dy;
    final olderY = tester.getTopLeft(find.text(olderDate)).dy;
    expect(latestY, lessThan(olderY));
  });

  group('пол и ИМТ', () {
    testWidgets('поле пола отображается, ИМТ скрыт без замеров', (
      tester,
    ) async {
      await pumpProfile(tester);

      expect(find.text('Пол'), findsOneWidget);
      expect(find.text('Мужской'), findsOneWidget);
      expect(find.text('Женский'), findsOneWidget);
      expect(find.textContaining('Индекс массы тела'), findsNothing);
    });

    testWidgets('выбор пола сохраняется в профиле', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text('Женский'));
      await tester.pumpAndSettle();

      expect((await profileRepo.get()).gender, 'female');

      // Значение восстанавливается после пересборки экрана.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpProfile(tester);
      final button = tester.widget<SegmentedButton<Gender>>(
        find.byType(SegmentedButton<Gender>),
      );
      expect(button.selected, {Gender.female});
    });

    testWidgets('без пола карточка ИМТ не показывается', (tester) async {
      await repo.add(measurement(weightKg: 70, heightCm: 175));

      await pumpProfile(tester);

      expect(find.textContaining('Индекс массы тела'), findsNothing);
    });

    testWidgets('ИМТ считается по последнему замеру и показывает шкалу', (
      tester,
    ) async {
      await repo.add(
        measurement(date: DateTime(2026, 8, 1), weightKg: 90, heightCm: 175),
      );
      await repo.add(
        measurement(date: DateTime(2026, 8, 10), weightKg: 70, heightCm: 175),
      );
      await profileRepo.setGender('male');

      await pumpProfile(tester);

      expect(find.text('Индекс массы тела (ИМТ)'), findsOneWidget);
      expect(find.text('22.9'), findsOneWidget);
      expect(find.text('Норма'), findsOneWidget);
      expect(find.text('Норма: 18.5–25 для вашего пола'), findsOneWidget);
      expect(find.text('Шкала ИМТ: от 15 до 40'), findsOneWidget);
    });

    testWidgets(
      'категория ИМТ учитывает пол: 24.5 — норма у мужчины, избыток у женщины',
      (tester) async {
        // 24.5 * 1.75² ≈ 75 кг.
        await repo.add(measurement(weightKg: 75, heightCm: 175));
        await profileRepo.setGender('male');

        await pumpProfile(tester);
        expect(find.text('24.5'), findsOneWidget);
        expect(find.text('Норма'), findsOneWidget);
        expect(find.text('Норма: 18.5–25 для вашего пола'), findsOneWidget);

        await profileRepo.setGender('female');
        await pumpProfile(tester);
        expect(find.text('Избыток массы'), findsOneWidget);
        expect(find.text('Норма: 19–24 для вашего пола'), findsOneWidget);
      },
    );

    testWidgets('без роста в замере ИМТ не рассчитывается', (tester) async {
      await repo.add(measurement(weightKg: 70));
      await profileRepo.setGender('female');

      await pumpProfile(tester);

      expect(find.textContaining('Индекс массы тела'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

List<double> _chartYs(WidgetTester tester) {
  final chart = tester.widget<LineChart>(find.byType(LineChart));
  final spots = chart.data.lineBarsData.first.spots;
  return [for (final spot in spots) spot.y];
}
