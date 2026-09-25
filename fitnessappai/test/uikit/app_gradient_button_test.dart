import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_gradient_button.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppGradientButton', () {
    testWidgets('рендерит label', (tester) async {
      await _pump(tester, AppGradientButton(label: 'Старт', onPressed: () {}));

      expect(find.text('Старт'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('без icon не рисует Icon', (tester) async {
      await _pump(tester, AppGradientButton(label: 'Старт', onPressed: () {}));

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('с иконкой рисует её', (tester) async {
      await _pump(
        tester,
        AppGradientButton(
          label: 'Старт',
          onPressed: () {},
          icon: Icons.play_arrow,
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('onPressed вызывается по тапу', (tester) async {
      var pressed = false;
      await _pump(
        tester,
        AppGradientButton(label: 'Старт', onPressed: () => pressed = true),
      );

      await tester.tap(find.text('Старт'));
      expect(pressed, isTrue);
    });
  });
}
