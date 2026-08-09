import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/main.dart';

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const FitnessAppAi());
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

  testWidgets('на самом узком экране (320dp) нет overflow', (tester) async {
    await pumpAtSize(tester, const Size(320, 640));
    expect(tester.takeException(), isNull);
  });
}
