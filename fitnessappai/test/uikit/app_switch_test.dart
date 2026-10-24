// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_switch.dart';

void main() {
  testWidgets('AppSwitch рендерит Switch и вызывает onChanged', (tester) async {
    var values = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppSwitch(value: false, onChanged: values.add)),
      ),
    );

    expect(find.byType(Switch), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(values, [true]);
  });

  testWidgets('AppSwitch onChanged: null — заблокирован', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AppSwitch(value: true))),
    );

    final s = tester.widget<Switch>(find.byType(Switch));
    expect(s.onChanged, isNull);
    expect(s.value, isTrue);
  });

  testWidgets('AppCheckbox рендерит Checkbox и вызывает onChanged', (
    tester,
  ) async {
    var values = <bool?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppCheckbox(value: false, onChanged: values.add)),
      ),
    );

    expect(find.byType(Checkbox), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(values, [true]);
  });
}
