// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_drawer.dart';
import 'package:fitnessappai/uikit/app_text.dart';

void main() {
  testWidgets('AppDrawer рендерит Drawer с содержимым', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: AppDrawer(child: AppText('Меню')),
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              child: const AppText('Открыть'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('Меню'), findsOneWidget);
  });
}
