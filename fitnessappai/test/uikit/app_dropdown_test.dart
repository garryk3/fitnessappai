// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_dropdown.dart';

void main() {
  testWidgets('AppDropdown открывает список, показывает пункты и выбирает', (
    tester,
  ) async {
    int? selected = 2;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AppDropdown<int?>(
              initialValue: selected,
              labelText: 'День недели',
              items: const [
                AppDropdownItem(value: null, label: 'Без дня'),
                AppDropdownItem(value: 1, label: 'Пн'),
                AppDropdownItem(value: 2, label: 'Вт'),
              ],
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    expect(find.text('День недели'), findsOneWidget);
    expect(find.text('Вт'), findsOneWidget);

    await tester.tap(find.byType(AppDropdown<int?>));
    await tester.pumpAndSettle();
    expect(find.text('Пн'), findsOneWidget);

    await tester.tap(find.text('Пн').last);
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  testWidgets('isExpanded/isDense прокидываются в InputDecoration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDropdown<String>(
            labelText: 'Тип',
            items: const [AppDropdownItem(value: 'a', label: 'А')],
            onChanged: (_) {},
            isExpanded: true,
            isDense: true,
          ),
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdown.decoration.isDense, isTrue);
    expect(dropdown.decoration.labelText, 'Тип');
    expect(dropdown.decoration.border, isA<OutlineInputBorder>());
    final inner = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(inner.isExpanded, isTrue);
  });
}
