// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_fab.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppFab', () {
    testWidgets('рендерит FloatingActionButton с иконкой и тапом', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        AppFab(
          icon: Icons.add,
          tooltip: 'Создать',
          heroTag: 'test-fab',
          onPressed: () => taps++,
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.heroTag, 'test-fab');
      await tester.tap(find.byType(FloatingActionButton));
      expect(taps, 1);
    });

    testWidgets('mini рендерит компактный вариант', (tester) async {
      await _pump(
        tester,
        AppFab(icon: Icons.stop_circle, mini: true, onPressed: () {}),
      );

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.mini, isTrue);
    });

    testWidgets('onPressed: null — неактивна, tooltip прокинут', (
      tester,
    ) async {
      await _pump(tester, AppFab(icon: Icons.add, tooltip: 'Создать'));

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.onPressed, isNull);
      expect(fab.tooltip, 'Создать');
    });
  });
}
