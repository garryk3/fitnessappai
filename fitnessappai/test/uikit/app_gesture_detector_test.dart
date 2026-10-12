// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_gesture_detector.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('AppGestureDetector', () {
    testWidgets('вызывает onTap', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        AppGestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      expect(taps, 1);
    });

    testWidgets('передаёт drag-колбэки', (tester) async {
      var updates = 0;
      await _pump(
        tester,
        AppGestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (_) => updates++,
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      await tester.drag(find.byType(GestureDetector), const Offset(40, 0));
      expect(updates, greaterThan(0));
    });
  });
}
