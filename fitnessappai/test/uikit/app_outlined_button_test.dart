// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_outlined_button.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppOutlinedButton', () {
    testWidgets('рендерит подпись и вызывает onPressed', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        AppOutlinedButton(label: 'Отмена', onPressed: () => taps++),
      );

      expect(find.text('Отмена'), findsOneWidget);
      await tester.tap(find.byType(OutlinedButton));
      expect(taps, 1);
    });

    testWidgets('busy показывает спиннер и блокирует нажатие', (tester) async {
      await _pump(
        tester,
        AppOutlinedButton(label: 'Отмена', busy: true, onPressed: () {}),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });
  });
}
