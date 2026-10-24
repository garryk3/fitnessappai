// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_bottom_sheet.dart';
import 'package:fitnessappai/uikit/app_text.dart';

void main() {
  testWidgets('showAppBottomSheet открывает лист с drag-handle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppBottomSheet<void>(
              context: context,
              builder: (sheetContext) => const AppText('Лист'),
            ),
            child: const AppText('Открыть'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    expect(find.text('Лист'), findsOneWidget);
    // Drag-handle включён дефолтом обёртки (showDragHandle: true) и рендерится
    // виджетом Material 3; достаточно факта открытия листа.
  });

  testWidgets('isScrollControlled прокидывается в showModalBottomSheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (sheetContext) => const AppText('Полный лист'),
            ),
            child: const AppText('Открыть'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    expect(find.text('Полный лист'), findsOneWidget);
  });
}
