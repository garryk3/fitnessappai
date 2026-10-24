// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_spinner.dart';

void main() {
  testWidgets('AppSpinner рендерит CircularProgressIndicator с M3-дефолтом', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: const Center(child: AppSpinner())),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final spinner = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(spinner.strokeWidth, isNull);
  });

  testWidgets('AppSpinner strokeWidth прокидывается', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 18,
            height: 18,
            child: AppSpinner(strokeWidth: 2),
          ),
        ),
      ),
    );

    final spinner = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(spinner.strokeWidth, 2);
  });
}
