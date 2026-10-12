// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_button.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppButton', () {
    testWidgets('рендерит подпись и вызывает onPressed', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        AppButton(label: 'Сохранить', onPressed: () => taps++),
      );

      expect(find.text('Сохранить'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 1);
    });

    testWidgets('onPressed: null — неактивна', (tester) async {
      await _pump(tester, const AppButton(label: 'Сохранить'));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('busy показывает спиннер и блокирует нажатие', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        AppButton(label: 'Сохранить', busy: true, onPressed: () => taps++),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Сохранить'), findsNothing);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('icon добавляет иконку', (tester) async {
      await _pump(
        tester,
        AppButton(label: 'Добавить', icon: Icons.add, onPressed: () {}),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('expanded растягивает на всю ширину', (tester) async {
      await _pump(
        tester,
        AppButton(label: 'Далее', expanded: true, onPressed: () {}),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(FilledButton),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, double.infinity);
    });
  });
}
