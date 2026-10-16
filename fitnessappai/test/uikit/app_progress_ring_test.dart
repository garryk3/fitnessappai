// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/uikit/app_progress_ring.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double textScale = 1.0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('AppProgressRing', () {
    testWidgets('рендерит подпись процента', (tester) async {
      await _pump(
        tester,
        const AppProgressRing(percent: 33, label: 'Прогресс 33%'),
      );

      expect(find.text('33%'), findsOneWidget);
    });

    testWidgets('процент выше 100 показывает реальное значение', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppProgressRing(percent: 133, label: 'Прогресс 133%'),
      );

      expect(find.text('133%'), findsOneWidget);
    });

    testWidgets('пробрасывает а11y-подпись', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AppProgressRing(percent: 50, label: 'Выполнено 50%'),
      );

      expect(find.bySemanticsLabel('Выполнено 50%'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('размер задаётся параметром size', (tester) async {
      await _pump(
        tester,
        const AppProgressRing(percent: 50, label: 'x', size: 64),
      );

      expect(tester.getSize(find.byType(AppProgressRing)), const Size(64, 64));
    });

    testWidgets(
      'подпись не обрезается при системном масштабе шрифта (Low 54.3)',
      (tester) async {
        await _pump(
          tester,
          const AppProgressRing(percent: 100, label: 'x'),
          textScale: 3.0,
        );

        // Замеряем визуальные границы (с учётом трансформа FittedBox):
        // layout-размер текста при scale 3.0 натуральный и шире кольца.
        final ring = tester.getSize(find.byType(AppProgressRing));
        final topLeft = tester.getTopLeft(find.text('100%'));
        final bottomRight = tester.getBottomRight(find.text('100%'));
        expect(bottomRight.dx - topLeft.dx, lessThanOrEqualTo(ring.width));
        expect(bottomRight.dy - topLeft.dy, lessThanOrEqualTo(ring.height));
      },
    );
  });
}
