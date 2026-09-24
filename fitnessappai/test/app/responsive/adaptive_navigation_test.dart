import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/main.dart';
import 'package:fitnessappai/app/widgets/profile_avatar.dart';

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

  testWidgets('на широком экране (900dp) — свернутый NavigationRail', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(900, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
  });

  testWidgets(
    'на широком экране (1200dp) — rail со всеми пунктами и «Настройки»',
    (tester) async {
      await pumpAtSize(tester, const Size(1200, 800));
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      // 6 вкладок навигации + «Настройки» последним пунктом.
      expect(rail.destinations, hasLength(7));
      expect((rail.destinations.last.label as Text).data, 'Настройки');
    },
  );

  testWidgets('на среднем экране (700dp) — компактный бар, а не rail', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(700, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
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

  testWidgets('иконка меню слева-сверху открывает drawer на узком экране', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(480, 800));
    expect(find.byIcon(Icons.menu), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    for (final label in ['Главная', 'Упражнения', 'Программы', 'План']) {
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text(label)),
        findsWidgets,
      );
    }
  });

  testWidgets('иконка rail-а разворачивает подписи и сворачивает обратно', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(1200, 800));
    // На expanded-экране иконка меню одна — в leading rail-а (в AppBar не
    // дублируется).
    expect(find.byIcon(Icons.menu), findsOneWidget);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(
      find
          .descendant(
            of: find.byType(NavigationRail),
            matching: find.text('Прогресс'),
          )
          .hitTestable(),
      findsNothing,
    );
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );
    expect(
      find
          .descendant(
            of: find.byType(NavigationRail),
            matching: find.text('Прогресс'),
          )
          .hitTestable(),
      findsWidgets,
    );
    await tester.tap(find.byIcon(Icons.menu_open));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );
  });

  testWidgets('на самом узком экране (320dp) нет overflow', (tester) async {
    await pumpAtSize(tester, const Size(320, 640));
    expect(tester.takeException(), isNull);
  });

  testWidgets('в шапке меню аватар и тап по нему открывает Профиль', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(480, 800));
    final scaffoldWithDrawer = find.byWidgetPredicate(
      (widget) => widget is Scaffold && widget.drawer != null,
    );
    tester.state<ScaffoldState>(scaffoldWithDrawer).openDrawer();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileAvatar), findsWidgets);
    await tester.tap(find.byType(ProfileAvatar).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Drawer), findsNothing);
    expect(find.widgetWithText(AppBar, 'Профиль'), findsOneWidget);
  });

  testWidgets(
    'в меню есть «Настройки» внизу (за divider-ом) и тап ведёт на экран настроек',
    (tester) async {
      await pumpAtSize(tester, const Size(480, 800));
      final scaffoldWithDrawer = find.byWidgetPredicate(
        (widget) => widget is Scaffold && widget.drawer != null,
      );
      tester.state<ScaffoldState>(scaffoldWithDrawer).openDrawer();
      await tester.pumpAndSettle();

      // «Настройки» — последний пункт, прикреплён к низу блока меню.
      final settingsTile = find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Настройки'),
      );
      expect(settingsTile, findsOneWidget);
      final drawerRect = tester.getRect(find.byType(Drawer));
      expect(
        tester.getTopLeft(settingsTile).dy,
        greaterThan(drawerRect.center.dy),
      );

      await tester.tap(settingsTile);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Drawer), findsNothing);
      expect(find.widgetWithText(AppBar, 'Настройки'), findsOneWidget);
    },
  );

  testWidgets(
    'на широком экране тап по «Настройки» в rail открывает экран настроек',
    (tester) async {
      await pumpAtSize(tester, const Size(1200, 800));
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.byIcon(Icons.settings_outlined),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(AppBar, 'Настройки'), findsOneWidget);
    },
  );

  testWidgets('с узкого экрана через меню открывается Прогресс без assertion', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(480, 800));
    final scaffoldWithDrawer = find.byWidgetPredicate(
      (widget) => widget is Scaffold && widget.drawer != null,
    );
    tester.state<ScaffoldState>(scaffoldWithDrawer).openDrawer();
    await tester.pumpAndSettle();
    // Дублирующий пункт «Профиль» в списке меню убран — доступ через аватар.
    expect(
      find.descendant(of: find.byType(Drawer), matching: find.text('Профиль')),
      findsNothing,
    );
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Прогресс')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Drawer), findsNothing);
    // Страница реально переключилась: заголовок AppBar выбранного экрана.
    expect(find.widgetWithText(AppBar, 'Прогресс'), findsOneWidget);
    // Бар на месте, но без подсветки: выбранная вкладка «План» не горит
    // (NavigationBarTheme с прозрачным индикатором).
    expect(find.byType(NavigationBar), findsOneWidget);
    final barTheme = tester.widget<NavigationBarTheme>(
      find.ancestor(
        of: find.byType(NavigationBar),
        matching: find.byType(NavigationBarTheme),
      ),
    );
    expect(barTheme.data.indicatorColor, Colors.transparent);
  });

  testWidgets(
    'смена размера на ходу с открытым Прогрессом (широкий → узкий) без assertion',
    (tester) async {
      await pumpAtSize(tester, const Size(1200, 800));
      // Открываем Прогресс (индекс 4) через rail.
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      rail.onDestinationSelected!(4);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Сужаем окно на ходу — NavigationBar должен корректно ограничить индекс.
      tester.view.physicalSize = const Size(480, 800);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      // Активация последней вкладки бара работает без assertion.
      await tester.tap(find.text('Главная'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
