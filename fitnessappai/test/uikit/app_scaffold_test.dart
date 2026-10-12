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

    testWidgets('scaffoldKey открывает drawer программно', (tester) async {
      final scaffoldKey = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        MaterialApp(
          home: AppScaffold(
            scaffoldKey: scaffoldKey,
            drawer: const Drawer(child: Text('Меню')),
            body: const Text('Тело'),
          ),
        ),
      );

      // Регресс (52.7): GlobalKey<ScaffoldState>, переданный в super.key,
      // висел на stateless-обёртке и давал currentState == null — открытие
      // drawer молча не работало.
      expect(scaffoldKey.currentState, isNotNull);
      scaffoldKey.currentState!.openDrawer();
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);
    });
  });
}
