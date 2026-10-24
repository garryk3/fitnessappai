// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_popup_menu_button.dart';
import 'package:fitnessappai/uikit/app_text.dart';

void main() {
  testWidgets('AppPopupMenuButton пасс-тру: рендер PopupMenuButton с tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppPopupMenuButton<String>(
              tooltip: 'Меню',
              itemBuilder: (context) => const [
                AppPopupMenuItem(value: 'edit', child: AppText('Править')),
                AppPopupMenuItem(value: 'delete', child: AppText('Удалить')),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    final popupMenuButton = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );
    expect(popupMenuButton.tooltip, 'Меню');
  });

  testWidgets(
    'AppPopupMenuButton: выбор пункта доставляет value в onSelected',
    (tester) async {
      final selected = <String>[];
      void collect(String? value) {
        if (value != null) selected.add(value);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppPopupMenuButton<String>(
                onSelected: collect,
                itemBuilder: (context) => const [
                  AppPopupMenuItem(value: 'edit', child: AppText('Править')),
                  AppPopupMenuItem(value: 'delete', child: AppText('Удалить')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppPopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Править'));
      await tester.pumpAndSettle();

      expect(selected, ['edit']);
    },
  );
}
