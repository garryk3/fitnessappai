// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_divider.dart';

void main() {
  testWidgets('AppDivider рендерит Divider с параметрами', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AppDivider(height: 24))),
    );

    expect(find.byType(Divider), findsOneWidget);
    expect(find.byType(VerticalDivider), findsNothing);
    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.height, 24);
  });

  testWidgets('AppVerticalDivider рендерит VerticalDivider', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              const SizedBox(width: 40),
              AppVerticalDivider(width: 1, thickness: 1),
              SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(VerticalDivider), findsOneWidget);
    final divider = tester.widget<VerticalDivider>(
      find.byType(VerticalDivider),
    );
    expect(divider.width, 1);
    expect(divider.thickness, 1);
  });
}
