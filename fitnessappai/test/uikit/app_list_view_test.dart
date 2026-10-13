// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_list_view.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppListView', () {
    testWidgets('рендерит всех детей', (tester) async {
      await _pump(
        tester,
        const AppListView(children: [Text('Раз'), Text('Два'), Text('Три')]),
      );

      expect(find.text('Раз'), findsOneWidget);
      expect(find.text('Два'), findsOneWidget);
      expect(find.text('Три'), findsOneWidget);
    });

    testWidgets('builder строит элементы из itemCount', (tester) async {
      await _pump(
        tester,
        AppListView.builder(
          itemCount: 3,
          itemBuilder: (context, index) => Text('Пункт $index'),
        ),
      );

      expect(find.text('Пункт 0'), findsOneWidget);
      expect(find.text('Пункт 2'), findsOneWidget);
    });

    testWidgets('separated вставляет разделители', (tester) async {
      await _pump(
        tester,
        AppListView.separated(
          itemCount: 3,
          itemBuilder: (context, index) => Text('Пункт $index'),
          separatorBuilder: (context, index) => const Divider(),
        ),
      );

      expect(find.text('Пункт 0'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('separated пробрасывает add* в SliverChildBuilderDelegate', (
      tester,
    ) async {
      await _pump(
        tester,
        AppListView.separated(
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
          itemCount: 2,
          itemBuilder: (context, index) => Text('Пункт $index'),
          separatorBuilder: (context, index) => const Divider(),
        ),
      );

      // Регресс (52.8, баг из 52.1): эти параметры конструктор `.separated`
      // принимал, но в `ListView.separated` не пробрасывал — молча игнорировались.
      final list = tester.widget<ListView>(find.byType(ListView));
      final delegate = list.childrenDelegate as SliverChildBuilderDelegate;
      expect(delegate.addAutomaticKeepAlives, isFalse);
      expect(delegate.addRepaintBoundaries, isFalse);
      expect(delegate.addSemanticIndexes, isFalse);
    });
  });
}
