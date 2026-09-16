import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/splash_gate.dart';

void main() {
  testWidgets('показывает заставку во время инициализации', (tester) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      SplashGate(
        bootstrap: () => completer.future,
        homeBuilder: () =>
            const MaterialApp(home: Scaffold(body: Text('Главный экран'))),
        splashBody: const ColoredBox(
          color: Colors.black,
          child: Center(child: Text('Заставка')),
        ),
      ),
    );

    expect(find.text('Заставка'), findsOneWidget);
    expect(find.text('Главный экран'), findsNothing);

    completer.complete();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Главный экран'), findsOneWidget);
    expect(find.text('Заставка'), findsNothing);
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
        splashBody: const ColoredBox(
          color: Colors.black,
          child: Center(child: Text('Заставка')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Заставка'), findsOneWidget);

    completer.complete();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Заставка'), findsNothing);
    expect(find.text('Главный экран'), findsOneWidget);
  });

  testWidgets('сплэш держится минимум 2 секунды до исчезновения', (
    tester,
  ) async {
    await tester.pumpWidget(
      SplashGate(
        bootstrap: () async {},
        homeBuilder: () =>
            const MaterialApp(home: Scaffold(body: Text('Главный экран'))),
        splashBody: const ColoredBox(
          color: Colors.black,
          child: Center(child: Text('Заставка')),
        ),
      ),
    );

    // Быстрая инициализация уже завершилась; через 1 секунду заставка ещё
    // должна быть видна.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Заставка'), findsOneWidget);
    expect(find.text('Главный экран'), findsNothing);

    // После полных 2 секунд начинается плавный переход к главному экрану.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Главный экран'), findsOneWidget);
    expect(find.text('Заставка'), findsNothing);
  });
}
