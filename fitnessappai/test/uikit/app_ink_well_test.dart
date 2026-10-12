// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_ink_well.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppInkWell', () {
    testWidgets('рендерит child и вызывает onTap', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        AppInkWell(onTap: () => taps++, child: const Text('Нажми')),
      );

      expect(find.text('Нажми'), findsOneWidget);
      await tester.tap(find.byType(InkWell));
      expect(taps, 1);
    });

    testWidgets('onTap: null — без реакции', (tester) async {
      await _pump(tester, const AppInkWell(child: Text('Нажми')));

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });
  });
}
