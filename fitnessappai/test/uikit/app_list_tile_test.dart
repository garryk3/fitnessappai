// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_icon.dart';
import 'package:fitnessappai/uikit/app_list_tile.dart';
import 'package:fitnessappai/uikit/app_text.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppListTile', () {
    testWidgets('рендерит ListTile с содержимым и вызывает onTap', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        AppListTile(
          leading: const AppIcon(Icons.fitness_center),
          title: const AppText('Название'),
          subtitle: const AppText('Тип'),
          trailing: const AppText('3'),
          onTap: () => taps++,
        ),
      );

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.text('Название'), findsOneWidget);
      expect(find.text('Тип'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await tester.tap(find.byType(ListTile));
      expect(taps, 1);
    });

    testWidgets('onTap: null — неактивен; dense/contentPadding прокидываются', (
      tester,
    ) async {
      const padding = EdgeInsets.symmetric(horizontal: 4);
      await _pump(
        tester,
        AppListTile(
          title: const AppText('Заголовок'),
          dense: true,
          contentPadding: padding,
        ),
      );

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.onTap, isNull);
      expect(tile.dense, isTrue);
      expect(tile.contentPadding, padding);
    });

    testWidgets('selected/selectedTileColor прокидываются', (tester) async {
      await _pump(
        tester,
        AppListTile(
          title: const AppText('Настройки'),
          selected: true,
          selectedTileColor: const Color(0xF0F0F0),
        ),
      );

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.selected, isTrue);
      expect(tile.selectedTileColor, const Color(0xF0F0F0));
    });
  });
}
