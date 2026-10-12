// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_icon.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppIcon', () {
    testWidgets('рендерит переданную иконку', (tester) async {
      await _pump(tester, const AppIcon(Icons.add));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('передаёт размер и цвет', (tester) async {
      await _pump(
        tester,
        const AppIcon(Icons.add, size: 32, color: Color(0xFF123456)),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 32);
      expect(icon.color, const Color(0xFF123456));
    });

    testWidgets('без size/color наследует IconTheme', (tester) async {
      await _pump(tester, const AppIcon(Icons.add));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, isNull);
      expect(icon.color, isNull);
    });
  });
}
