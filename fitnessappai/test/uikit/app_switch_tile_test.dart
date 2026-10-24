// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_icon.dart';
import 'package:fitnessappai/uikit/app_switch_tile.dart';
import 'package:fitnessappai/uikit/app_text.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppSwitchTile', () {
    testWidgets('рендерит SwitchListTile и тапает переключатель и строку', (
      tester,
    ) async {
      var values = <bool>[];
      await _pump(
        tester,
        AppSwitchTile(
          title: const AppText('Тумблер'),
          subtitle: const AppText('Описание'),
          secondary: const AppIcon(Icons.visibility_outlined),
          value: false,
          onChanged: values.add,
        ),
      );

      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      expect(values, [true]);
    });

    testWidgets('onChanged: null — заблокирован', (tester) async {
      await _pump(
        tester,
        AppSwitchTile(title: const AppText('Тумблер'), value: true),
      );

      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.onChanged, isNull);
      expect(tile.value, isTrue);
    });

    testWidgets('contentPadding/dense прокидываются', (tester) async {
      await _pump(
        tester,
        AppSwitchTile(
          title: const AppText('Тумблер'),
          value: true,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      );

      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.contentPadding, EdgeInsets.zero);
      expect(tile.dense, isTrue);
    });
  });

  group('AppCheckboxTile', () {
    testWidgets(
      'controlAffinity: leading рендерит чекбокс слева и тапает строку',
      (tester) async {
        var values = <bool?>[];
        await _pump(
          tester,
          AppCheckboxTile(
            title: const AppText('Подтвердить'),
            value: false,
            onChanged: values.add,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );

        expect(find.byType(CheckboxListTile), findsOneWidget);
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        expect(values, [true]);
      },
    );
  });
}
