import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_card.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppCard', () {
    testWidgets('рендерит child', (tester) async {
      await _pump(tester, const AppCard(child: Text('Контент')));

      expect(find.text('Контент'), findsOneWidget);
    });

    testWidgets('по умолчанию фон surfaceContainerLow и нет градиента', (
      tester,
    ) async {
      await _pump(tester, const AppCard(child: Text('Контент')));

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Контент'),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, isNotNull);
      expect(decoration.gradient, isNull);
      expect(decoration.borderRadius, BorderRadius.circular(20));
    });

    testWidgets('с градиентом не задаёт color', (tester) async {
      await _pump(
        tester,
        AppCard(
          gradient: const LinearGradient(colors: [Colors.blue, Colors.red]),
          child: const Text('Контент'),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Контент'),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.gradient, isNotNull);
      expect(decoration.color, isNull);
    });

    testWidgets('borderColor добавляет рамку', (tester) async {
      await _pump(
        tester,
        const AppCard(borderColor: Colors.red, child: Text('Контент')),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Контент'),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, Border.all(color: Colors.red, width: 1.5));
    });

    testWidgets('кастомный padding применяется', (tester) async {
      await _pump(
        tester,
        const AppCard(padding: EdgeInsets.all(4), child: Text('Контент')),
      );

      final padding = tester.widget<Padding>(
        find.byWidgetPredicate(
          (w) => w is Padding && w.padding == const EdgeInsets.all(4),
        ),
      );
      expect(padding.padding, const EdgeInsets.all(4));
    });

    testWidgets('onTap вызывает обработчик', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        AppCard(onTap: () => tapped = true, child: const Text('Контент')),
      );

      await tester.tap(find.text('Контент'));
      expect(tapped, isTrue);
    });
  });
}
