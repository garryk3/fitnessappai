import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_tile.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppTile', () {
    testWidgets('рендерит title и subtitle', (tester) async {
      await _pump(
        tester,
        const AppTile(title: 'Заголовок', subtitle: 'Подзаголовок'),
      );

      expect(find.text('Заголовок'), findsOneWidget);
      expect(find.text('Подзаголовок'), findsOneWidget);
    });

    testWidgets('рендерит leading и trailing', (tester) async {
      await _pump(
        tester,
        const AppTile(
          title: 'Заголовок',
          leading: Icon(Icons.notifications),
          trailing: Icon(Icons.chevron_right),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('onTap вызывается по тапу', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        AppTile(title: 'Заголовок', onTap: () => tapped = true),
      );

      await tester.tap(find.text('Заголовок'));
      expect(tapped, isTrue);
    });
  });
}
