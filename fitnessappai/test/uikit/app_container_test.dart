// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_container.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppContainer', () {
    testWidgets('рендерит child и применяет параметры', (tester) async {
      await _pump(
        tester,
        const AppContainer(
          width: 120,
          height: 40,
          padding: EdgeInsets.all(8),
          child: Text('Контент'),
        ),
      );

      expect(find.text('Контент'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints, isNotNull);
    });
  });
}
