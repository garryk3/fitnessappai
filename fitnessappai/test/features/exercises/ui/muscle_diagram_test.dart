import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/features/exercises/ui/muscle_diagram.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('рендерит вид спереди без ошибок', (tester) async {
    await tester.pumpWidget(wrap(const MuscleDiagram(view: MuscleView.front)));

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(MuscleDiagram),
        matching: find.byType(SvgPicture),
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
        matching: find.byType(SvgPicture),
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

  testWidgets('подсветка отображается при наличии активных групп', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const MuscleDiagram(view: MuscleView.front, highlights: {'chest': 1.0}),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(MuscleDiagram),
        matching: find.byType(SvgPicture),
      ),
      findsOneWidget,
    );
  });
}
