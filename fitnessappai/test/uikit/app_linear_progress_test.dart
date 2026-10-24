// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_linear_progress.dart';

void main() {
  testWidgets('AppLinearProgress рендерит LinearProgressIndicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppLinearProgress(value: 0.4, minHeight: 6)),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.4);
    expect(bar.minHeight, 6);
  });
}
