// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_top_bar.dart';

void main() {
  group('AppTopBar', () {
    testWidgets('рендерит строковый заголовок', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(appBar: AppTopBar(title: 'История')),
        ),
      );

      expect(find.text('История'), findsOneWidget);
    });

    testWidgets('titleWidget приоритетнее title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppTopBar(title: 'Строка', titleWidget: Text('Виджет')),
          ),
        ),
      );

      expect(find.text('Виджет'), findsOneWidget);
      expect(find.text('Строка'), findsNothing);
    });

    testWidgets('рендерит actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppTopBar(
              title: 'Экран',
              actions: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
