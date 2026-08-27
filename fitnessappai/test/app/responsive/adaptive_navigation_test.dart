import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/main.dart';

import '../../helpers/test_services.dart';

void main() {
  setUp(registerTestServices);

  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const FitnessAppAi());
  }

  double navLabelOpacity(WidgetTester tester, String label) {
    final text = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: text, matching: find.byType(FadeTransition)).first,
    );
    return fade.opacity.value;
  }

  testWidgets('на узком экране — NavigationBar', (tester) async {
    await pumpAtSize(tester, const Size(480, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('на среднем экране — NavigationBar', (tester) async {
    await pumpAtSize(tester, const Size(800, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('на широком экране (>=840dp) — NavigationRail', (tester) async {
    await pumpAtSize(tester, const Size(1200, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('на широком экране нет overflow', (tester) async {
    await pumpAtSize(tester, const Size(1200, 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('навигация по вкладкам работает через NavigationRail', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(1200, 800));
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Профиль'), findsWidgets);
  });

  testWidgets('на узком экране (<400dp) подписи навигации скрыты', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(360, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Главная'), findsWidgets);
    expect(navLabelOpacity(tester, 'Главная'), 0.0);
    // «Программы» видна на всех размерах экрана.
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Программы'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.fitness_center_outlined), findsOneWidget);
  });

  testWidgets('на экране 400–600dp вкладка «Программы» видна', (tester) async {
    await pumpAtSize(tester, const Size(500, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Программы'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('порядок вкладок одинаковый на узком и среднем экране', (
    tester,
  ) async {
    // Порядок читаем через вкладки NavigationBar.
    Future<List<String>> destinationLabels(Size size) async {
      await pumpAtSize(tester, size);
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      return bar.destinations
          .map((d) => (d as NavigationDestination).label)
          .toList();
    }

    const expected = [
      'Главная',
      'Упражнения',
      'Программы',
      'План',
      'Прогресс',
      'Профиль',
    ];
    expect(await destinationLabels(const Size(360, 800)), expected);
    expect(await destinationLabels(const Size(800, 800)), expected);
  });

  testWidgets('на широком экране подписи навигации скрыты', (tester) async {
    await pumpAtSize(tester, const Size(800, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Главная'),
      ),
      findsOneWidget,
    );
    expect(navLabelOpacity(tester, 'Главная'), 0.0);
  });

  testWidgets('на самом узком экране (320dp) нет overflow', (tester) async {
    await pumpAtSize(tester, const Size(320, 640));
    expect(tester.takeException(), isNull);
  });
}
