import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_text_button.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppTextButton', () {
    testWidgets('рендерит подпись и вызывает onPressed', (tester) async {
      var taps = 0;
      await _pump(tester, AppTextButton(label: 'Ещё', onPressed: () => taps++));

      expect(find.text('Ещё'), findsOneWidget);
      await tester.tap(find.byType(TextButton));
      expect(taps, 1);
    });

    testWidgets('onPressed: null — неактивна', (tester) async {
      await _pump(tester, const AppTextButton(label: 'Ещё'));

      final button = tester.widget<TextButton>(find.byType(TextButton));
      expect(button.onPressed, isNull);
    });
  });
}
