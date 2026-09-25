import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_section.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppSection', () {
    testWidgets('рендерит заголовок и содержимое', (tester) async {
      await _pump(
        tester,
        const AppSection(title: 'Мышцы', child: Text('Описание')),
      );

      expect(find.text('Мышцы'), findsOneWidget);
      expect(find.text('Описание'), findsOneWidget);
    });
  });
}
