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

  testWidgets('на узком экране (480dp) — NavigationBar с подписями', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(480, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    for (final label in ['Главная', 'Упражнения', 'Программы', 'План']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('на широком экране (800dp) — всегда развёрнутый NavigationRail', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(800, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('на широком экране (1200dp) — rail со всеми шестью пунктами', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(1200, 800));
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations, hasLength(6));
  });

  testWidgets('на среднем экране (700dp) — rail, а не бар', (tester) async {
    await pumpAtSize(tester, const Size(700, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('первые четыре вкладки одинаковые на всех размерах', (
    tester,
  ) async {
    const labels = ['Главная', 'Упражнения', 'Программы', 'План'];
    for (final size in [const Size(480, 800), const Size(1200, 800)]) {
      await pumpAtSize(tester, size);
      for (final label in labels) {
        expect(find.text(label), findsWidgets);
      }
    }
  });

  testWidgets('выезжающее слева меню на узком экране', (tester) async {
    await pumpAtSize(tester, const Size(480, 800));
    // Выбираем Scaffold с drawer (внешний), а не вложенные экраны.
    final scaffoldWithDrawer = find.byWidgetPredicate(
      (widget) => widget is Scaffold && widget.drawer != null,
    );
    tester.state<ScaffoldState>(scaffoldWithDrawer).openDrawer();
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    for (final label in ['Главная', 'Упражнения', 'Программы', 'План']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('на самом узком экране (320dp) нет overflow', (tester) async {
    await pumpAtSize(tester, const Size(320, 640));
    expect(tester.takeException(), isNull);
  });
}
