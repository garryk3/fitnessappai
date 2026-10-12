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

    testWidgets('null-иконка рендерит пустое место (как Icon)', (tester) async {
      await _pump(tester, const AppIcon(null, size: 40));

      final icon = tester.widget<Icon>(
        find.byWidgetPredicate((w) => w is Icon && w.icon == null),
      );
      expect(icon.icon, isNull);
      expect(find.byType(SizedBox), findsOneWidget);
      expect(tester.getSize(find.byType(SizedBox)), const Size(40, 40));
    });

    testWidgets('пробрасывает расширенные параметры Icon', (tester) async {
      await _pump(
        tester,
        const AppIcon(
          Icons.add,
          fill: 0.5,
          weight: 2,
          grade: 1,
          opticalSize: 32,
          applyTextScaling: true,
          blendMode: BlendMode.srcOver,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Color(0xFF000000), blurRadius: 2)],
          semanticLabel: 'добавить',
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.fill, 0.5);
      expect(icon.weight, 2);
      expect(icon.grade, 1);
      expect(icon.opticalSize, 32);
      expect(icon.applyTextScaling, isTrue);
      expect(icon.blendMode, BlendMode.srcOver);
      expect(icon.fontWeight, FontWeight.w700);
      expect(icon.shadows, hasLength(1));
      expect(icon.semanticLabel, 'добавить');
    });
  });
}
