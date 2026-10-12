// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_scaffold.dart';

void main() {
  group('AppScaffold', () {
    testWidgets('рендерит body и appBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            appBar: AppBar(title: const Text('Экран')),
            body: const Text('Тело'),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Тело'), findsOneWidget);
      expect(find.text('Экран'), findsOneWidget);
    });
  });
}
