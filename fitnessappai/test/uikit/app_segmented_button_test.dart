// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/app/theme/app_tokens.dart';
import 'package:fitnessappai/uikit/app_segmented_button.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: child),
    ),
  );
}

enum _Period { week, month }

void main() {
  group('AppSegmentedButton', () {
    testWidgets('рендерит подписи всех сегментов', (tester) async {
      await _pump(
        tester,
        AppSegmentedButton<_Period>(
          segments: const [
            AppSegment(value: _Period.week, label: 'Неделя'),
            AppSegment(value: _Period.month, label: 'Месяц'),
          ],
          selected: const {_Period.week},
          onSelectionChanged: (_) {},
        ),
      );

      expect(find.text('Неделя'), findsOneWidget);
      expect(find.text('Месяц'), findsOneWidget);
    });

    testWidgets('тап по сегменту вызывает onSelectionChanged', (tester) async {
      Set<_Period>? received;
      await _pump(
        tester,
        AppSegmentedButton<_Period>(
          segments: const [
            AppSegment(value: _Period.week, label: 'Неделя'),
            AppSegment(value: _Period.month, label: 'Месяц'),
          ],
          selected: const {_Period.week},
          onSelectionChanged: (selection) => received = selection,
        ),
      );

      await tester.tap(find.text('Месяц'));
      expect(received, {_Period.month});
    });

    testWidgets('форма — пилюля (AppRadii.pill)', (tester) async {
      await _pump(
        tester,
        AppSegmentedButton<_Period>(
          segments: const [
            AppSegment(value: _Period.week, label: 'Неделя'),
            AppSegment(value: _Period.month, label: 'Месяц'),
          ],
          selected: const {_Period.week},
          onSelectionChanged: (_) {},
        ),
      );

      final SegmentedButton<_Period> button = tester
          .widget<SegmentedButton<_Period>>(
            find.byType(SegmentedButton<_Period>),
          );
      final RoundedRectangleBorder shape =
          button.style!.shape!.resolve(const {})! as RoundedRectangleBorder;
      expect((shape.borderRadius as BorderRadius).topLeft.x, AppRadii.pill);
    });

    testWidgets('expanded растягивает сегменты на ширину', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: AppSegmentedButton<_Period>(
                  expanded: true,
                  segments: const [
                    AppSegment(value: _Period.week, label: 'Неделя'),
                    AppSegment(value: _Period.month, label: 'Месяц'),
                  ],
                  selected: const {_Period.week},
                  onSelectionChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      final Row row = tester.widget<Row>(find.byType(Row));
      expect(row.children.single, isA<Expanded>());
    });

    testWidgets('onSelectionChanged=null — не реагирует на тап', (
      tester,
    ) async {
      await _pump(
        tester,
        AppSegmentedButton<_Period>(
          segments: const [
            AppSegment(value: _Period.week, label: 'Неделя'),
            AppSegment(value: _Period.month, label: 'Месяц'),
          ],
          selected: const {_Period.week},
        ),
      );

      final SegmentedButton<_Period> button = tester
          .widget<SegmentedButton<_Period>>(
            find.byType(SegmentedButton<_Period>),
          );
      expect(button.onSelectionChanged, isNull);
    });
  });
}
