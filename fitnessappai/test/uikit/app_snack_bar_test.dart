// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_snack_bar.dart';
import 'package:fitnessappai/uikit/app_text.dart';

void main() {
  testWidgets('showAppSnackBar показывает снекбар с текстом', (tester) async {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: Scaffold(body: Builder(builder: (context) => const SizedBox())),
      ),
    );

    showAppSnackBar(messengerKey.currentState!, 'Готово');
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(AppText), findsOneWidget);
    expect(find.text('Готово'), findsOneWidget);
  });
}
