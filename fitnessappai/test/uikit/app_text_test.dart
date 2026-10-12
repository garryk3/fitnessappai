// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_text.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppText', () {
    testWidgets('рендерит текст', (tester) async {
      await _pump(tester, const AppText('Привет'));

      expect(find.text('Привет'), findsOneWidget);
    });

    testWidgets('без style не навязывает стиль (наследует DefaultTextStyle)', (
      tester,
    ) async {
      await _pump(tester, const AppText('Привет'));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style, isNull);
    });

    testWidgets('передаёт style, выравнивание, лимиты и overflow', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 20);
      await _pump(
        tester,
        const AppText(
          'Длинный текст',
          style: style,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style, style);
      expect(text.textAlign, TextAlign.center);
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('AppText.rich рендерит несколько фрагментов', (tester) async {
      await _pump(
        tester,
        const AppText.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Итого: '),
              TextSpan(
                text: '75 кг',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, isNull);
      expect(text.textSpan, isA<TextSpan>());
      expect(find.textContaining('75 кг', findRichText: true), findsOneWidget);
    });
  });
}
