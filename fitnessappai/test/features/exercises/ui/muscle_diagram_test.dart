import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/features/exercises/ui/muscle_diagram.dart';

void main() {
  const expectedRegionKeys = <String>{
    'abs',
    'obliques',
    'chest',
    'shoulders',
    'shoulders_front',
    'shoulders_middle',
    'shoulders_rear',
    'biceps',
    'triceps',
    'forearms',
    'traps',
    'lats',
    'lower_back',
    'glutes',
    'quads',
    'hamstrings',
    'calves',
    'neck',
  };

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(body: Center(child: child)),
  );

  MuscleDiagramPainter painter(
    Map<String, double> highlights, {
    MuscleView view = MuscleView.front,
  }) {
    return MuscleDiagramPainter(
      view: view,
      highlights: highlights,
      baseColor: const Color(0xFF111111),
      highlightColor: const Color(0xFFFF0000),
      outlineColor: const Color(0xFF888888),
    );
  }

  testWidgets('рендерит вид спереди без ошибок', (tester) async {
    await tester.pumpWidget(wrap(const MuscleDiagram(view: MuscleView.front)));

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(MuscleDiagram),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('рендерит вид сзади без ошибок', (tester) async {
    await tester.pumpWidget(wrap(const MuscleDiagram(view: MuscleView.back)));

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(MuscleDiagram),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('рендерит с подсветкой без ошибок', (tester) async {
    await tester.pumpWidget(
      wrap(
        const MuscleDiagram(
          view: MuscleView.front,
          highlights: {'chest': 1.0, 'biceps': 0.5},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('регионы front и back покрывают все 18 групп', () {
    final front = MuscleDiagramPainter.regionKeysFor(MuscleView.front);
    final back = MuscleDiagramPainter.regionKeysFor(MuscleView.back);

    expect(front.union(back), expectedRegionKeys);
  });

  test('дельты разнесены по видам: front/middle спереди, rear сзади', () {
    final front = MuscleDiagramPainter.regionKeysFor(MuscleView.front);
    final back = MuscleDiagramPainter.regionKeysFor(MuscleView.back);

    expect(front, containsAll({'shoulders_front', 'shoulders_middle'}));
    expect(back, contains('shoulders_rear'));
    expect(front, isNot(contains('shoulders_rear')));
    expect(back, isNot(containsAll({'shoulders_front', 'shoulders_middle'})));
  });

  test('shouldRepaint учитывает изменение highlights', () {
    final base = painter(const {'chest': 1.0});

    expect(
      base.shouldRepaint(painter(const {'chest': 1.0})),
      isFalse,
      reason: 'идентичные параметры не требуют перерисовки',
    );
    expect(
      base.shouldRepaint(painter(const {'chest': 0.5})),
      isTrue,
      reason: 'изменение интенсивности требует перерисовки',
    );
    expect(
      base.shouldRepaint(painter(const {'chest': 1.0}, view: MuscleView.back)),
      isTrue,
      reason: 'изменение вида требует перерисовки',
    );
  });

  testWidgets('подсветка анимируется плавно к целевой интенсивности', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const MuscleDiagram(view: MuscleView.front, highlights: {'chest': 1.0}),
      ),
    );

    double currentIntensity() {
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(MuscleDiagram),
          matching: find.byType(CustomPaint),
        ),
      );
      return (customPaint.painter! as MuscleDiagramPainter)
              .highlights['chest'] ??
          0.0;
    }

    expect(currentIntensity(), 0.0);

    await tester.pump(MuscleDiagram.animationDuration ~/ 2);

    final mid = currentIntensity();
    expect(mid, greaterThan(0.0));
    expect(mid, lessThan(1.0));

    await tester.pumpAndSettle();

    expect(currentIntensity(), 1.0);
  });
}
