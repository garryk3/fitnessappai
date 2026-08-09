import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/responsive/two_pane_layout.dart';

void main() {
  testWidgets('TwoPaneLayout показывает обе панели с разделителем', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TwoPaneLayout(
          leading: Container(key: const ValueKey('leading')),
          trailing: Container(key: const ValueKey('trailing')),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('leading')), findsOneWidget);
    expect(find.byKey(const ValueKey('trailing')), findsOneWidget);
    expect(find.byType(VerticalDivider), findsOneWidget);
  });

  testWidgets('TwoPaneLayout соблюдает ширину ведущей панели', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TwoPaneLayout(
          leadingWidth: 300,
          leading: Container(key: const ValueKey('leading')),
          trailing: Container(key: const ValueKey('trailing')),
        ),
      ),
    );
    final leading = tester.getSize(find.byKey(const ValueKey('leading')));
    expect(leading.width, 300);
  });
}
