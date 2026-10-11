import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_grid_view.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppGridView', () {
    testWidgets('count рендерит всех детей', (tester) async {
      await _pump(
        tester,
        const AppGridView.count(
          crossAxisCount: 2,
          children: [Text('A'), Text('B')],
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('builder использует переданный делегат', (tester) async {
      await _pump(
        tester,
        AppGridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          itemCount: 2,
          itemBuilder: (context, index) => Text('Ячейка $index'),
        ),
      );

      expect(find.text('Ячейка 0'), findsOneWidget);
      expect(find.text('Ячейка 1'), findsOneWidget);
    });
  });
}
