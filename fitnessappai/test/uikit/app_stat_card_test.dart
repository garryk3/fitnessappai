import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_stat_card.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppStatCard', () {
    testWidgets('рендерит иконку, значение и подпись', (tester) async {
      await _pump(
        tester,
        const AppStatCard(
          label: 'Тренировки',
          value: '12',
          icon: Icons.fitness_center,
        ),
      );

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Тренировки'), findsOneWidget);
    });
  });
}
