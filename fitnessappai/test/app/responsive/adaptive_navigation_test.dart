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
    // На экранах < 400dp вкладка «Программы» скрыта из нижней навигации.
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Программы'),
      ),
      findsNothing,
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

  testWidgets('на широком экране подписи навигации присутствуют', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(800, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Главная'),
      ),
      findsOneWidget,
    );
    expect(navLabelOpacity(tester, 'Главная'), 1.0);
  });

  testWidgets('на самом узком экране (320dp) нет overflow', (tester) async {
    await pumpAtSize(tester, const Size(320, 640));
    expect(tester.takeException(), isNull);
  });
}
