// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_icon.dart';
import 'package:fitnessappai/uikit/app_icon_button.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppIconButton', () {
    testWidgets('рендерит IconButton с иконкой и вызывает onPressed', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        AppIconButton(
          icon: const AppIcon(Icons.add),
          tooltip: 'Добавить',
          onPressed: () => taps++,
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.tooltip, 'Добавить');
      await tester.tap(find.byType(IconButton));
      expect(taps, 1);
    });

    testWidgets('withTooltip читается семантикой (long-press)', (tester) async {
      await _pump(
        tester,
        AppIconButton(
          icon: const AppIcon(Icons.add),
          tooltip: 'Добавить',
          onPressed: () {},
        ),
      );

      await tester.longPress(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text('Добавить'), findsOneWidget);
    });

    testWidgets('onPressed: null — неактивна', (tester) async {
      await _pump(tester, AppIconButton(icon: const AppIcon(Icons.add)));

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('color/visualDensity прокидываются', (tester) async {
      const color = Color(0xFF00FF00);
      await _pump(
        tester,
        AppIconButton(
          icon: const AppIcon(Icons.settings),
          color: color,
          visualDensity: VisualDensity.compact,
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.color, color);
      expect(button.visualDensity, VisualDensity.compact);
    });
  });
}
