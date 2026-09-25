import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_empty_state.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppEmptyState', () {
    testWidgets('рендерит иконку, заголовок и хинт', (tester) async {
      await _pump(
        tester,
        const AppEmptyState(
          icon: Icons.star_outline,
          title: 'Заголовок',
          hint: 'Подсказка',
        ),
      );

      expect(find.byIcon(Icons.star_outline), findsOneWidget);
      expect(find.text('Заголовок'), findsOneWidget);
      expect(find.text('Подсказка'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('с действием рендерит кнопку', (tester) async {
      var pressed = false;
      await _pump(
        tester,
        AppEmptyState(
          icon: Icons.star_outline,
          title: 'Заголовок',
          hint: 'Подсказка',
          actionLabel: 'Действие',
          onAction: () => pressed = true,
        ),
      );

      expect(find.text('Действие'), findsOneWidget);
      await tester.tap(find.text('Действие'));
      expect(pressed, isTrue);
    });

    testWidgets('без onAction кнопку не рисует', (tester) async {
      await _pump(
        tester,
        const AppEmptyState(
          icon: Icons.star_outline,
          title: 'Заголовок',
          hint: 'Подсказка',
          actionLabel: 'Действие',
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
