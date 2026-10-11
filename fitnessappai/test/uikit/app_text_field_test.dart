import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_text_field.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppTextField', () {
    testWidgets('рендерит labelText и вводит текст в controller', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        AppTextField(controller: controller, labelText: 'Вес'),
      );

      expect(find.text('Вес'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '75');
      expect(controller.text, '75');
    });

    testWidgets('явная decoration переопределяет удобные поля', (tester) async {
      await _pump(
        tester,
        const AppTextField(
          labelText: 'Игнор',
          decoration: InputDecoration(hintText: 'Подсказка'),
        ),
      );

      expect(find.text('Подсказка'), findsOneWidget);
      expect(find.text('Игнор'), findsNothing);
    });
  });
}
