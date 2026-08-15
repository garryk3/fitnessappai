import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/splash_gate.dart';

void main() {
  testWidgets('показывает логотип во время инициализации', (tester) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      SplashGate(
        bootstrap: () => completer.future,
        homeBuilder: () =>
            const MaterialApp(home: Scaffold(body: Text('Главный экран'))),
      ),
    );

    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    expect(find.text('Личный тренер'), findsOneWidget);
    expect(find.text('Главный экран'), findsNothing);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.text('Главный экран'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsNothing);
  });

  testWidgets('заставка исчезает после завершения инициализации', (
    tester,
  ) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      SplashGate(
        bootstrap: () => completer.future,
        homeBuilder: () =>
            const MaterialApp(home: Scaffold(body: Text('Главный экран'))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.fitness_center), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.fitness_center), findsNothing);
    expect(find.text('Главный экран'), findsOneWidget);
  });
}
