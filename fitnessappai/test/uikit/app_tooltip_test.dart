// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_tooltip.dart';
import 'package:fitnessappai/uikit/app_icon.dart';

void main() {
  testWidgets('AppTooltip показывает сообщение по long-press', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppTooltip(
              message: 'Подсказка',
              child: AppIcon(Icons.info_outline),
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(AppTooltip));
    await tester.pumpAndSettle();
    expect(find.text('Подсказка'), findsOneWidget);
  });

  testWidgets('message: пустой — без подсказки, ребёнок рендерится', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppTooltip(message: '', child: AppIcon(Icons.info_outline)),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    await tester.longPress(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(find.byType(Tooltip), findsNothing);
  });
}
