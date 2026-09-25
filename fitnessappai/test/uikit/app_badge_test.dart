import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_badge.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppBadge', () {
    testWidgets('рендерит label', (tester) async {
      await _pump(tester, const AppBadge(label: 'Тест'));

      expect(find.text('Тест'), findsOneWidget);
    });

    testWidgets('без иконки не рисует placeholder', (tester) async {
      await _pump(tester, const AppBadge(label: 'Без иконки'));

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('с иконкой рисует Icon заданного размера', (tester) async {
      await _pump(tester, const AppBadge(label: 'Тест', icon: Icons.warning));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.warning);
      expect(icon.size, 13);
    });

    testWidgets('применяет цвета фона и текста', (tester) async {
      const background = Color(0xFFEADDFF);
      const foreground = Color(0xFF21005D);
      await _pump(
        tester,
        const AppBadge(
          label: 'Тест',
          background: background,
          foreground: foreground,
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('Тест'), matching: find.byType(Container)),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, background);

      final text = tester.widget<Text>(find.text('Тест'));
      expect(text.style?.color, foreground);
    });

    testWidgets('кастомный borderRadius и padding применяются', (tester) async {
      await _pump(
        tester,
        AppBadge(
          label: 'Тест',
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.all(10),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('Тест'), matching: find.byType(Container)),
      );
      expect(container.padding, const EdgeInsets.all(10));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });
  });
}
