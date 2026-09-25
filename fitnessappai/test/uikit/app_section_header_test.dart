import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_section_header.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppSectionHeader', () {
    testWidgets('рендерит title', (tester) async {
      await _pump(tester, const AppSectionHeader(title: 'Секция'));

      expect(find.text('Секция'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('с действием рендерит кнопку', (tester) async {
      var pressed = false;
      await _pump(
        tester,
        AppSectionHeader(
          title: 'Секция',
          actionLabel: 'Открыть',
          onAction: () => pressed = true,
        ),
      );

      expect(find.text('Открыть'), findsOneWidget);
      await tester.tap(find.text('Открыть'));
      expect(pressed, isTrue);
    });

    testWidgets('без onAction кнопку не рисует', (tester) async {
      await _pump(
        tester,
        const AppSectionHeader(title: 'Секция', actionLabel: 'Открыть'),
      );

      expect(find.byType(TextButton), findsNothing);
    });
  });
}
