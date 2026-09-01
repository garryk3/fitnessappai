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

  String svgString(WidgetTester tester) {
    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    return (picture.bytesLoader as SvgStringLoader).provideSvg(null);
  }

  int activeCount(WidgetTester tester) =>
      'url(#activeGradient)'.allMatches(svgString(tester)).length;

  testWidgets('рендерит вид спереди без ошибок', (tester) async {
    await tester.pumpWidget(wrap(const MuscleDiagram(view: MuscleView.front)));

    expect(tester.takeException(), isNull);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('рендерит вид сзади без ошибок', (tester) async {
    await tester.pumpWidget(wrap(const MuscleDiagram(view: MuscleView.back)));

    expect(tester.takeException(), isNull);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('без подсветки нет активных путей', (tester) async {
    await tester.pumpWidget(wrap(const MuscleDiagram(view: MuscleView.front)));

    expect(activeCount(tester), 0);
  });

  testWidgets('все группы переднего вида подсвечиваются', (tester) async {
    const frontKeys = <String>{
      'neck',
      'chest',
      'abs',
      'obliques',
      'biceps',
      'forearms',
      'quads',
      'shoulders',
      'shoulders_front',
      'shoulders_middle',
    };

    for (final key in frontKeys) {
      await tester.pumpWidget(
        wrap(MuscleDiagram(view: MuscleView.front, highlights: {key: 1.0})),
      );
      expect(
        activeCount(tester),
        greaterThan(0),
        reason: 'группа "$key" должна подсвечиваться на переднем виде',
      );
    }
  });

  testWidgets('все группы заднего вида подсвечиваются', (tester) async {
    const backKeys = <String>{
      'neck',
      'triceps',
      'forearms',
      'traps',
      'lats',
      'lower_back',
      'glutes',
      'hamstrings',
      'calves',
      'shoulders',
      'shoulders_rear',
    };

    for (final key in backKeys) {
      await tester.pumpWidget(
        wrap(MuscleDiagram(view: MuscleView.back, highlights: {key: 1.0})),
      );
      expect(
        activeCount(tester),
        greaterThan(0),
        reason: 'группа "$key" должна подсвечиваться на заднем виде',
      );
    }
  });

  testWidgets('в переднем виде нет лишнего элемента между ног', (tester) async {
    await tester.pumpWidget(wrap(const MuscleDiagram(view: MuscleView.front)));

    final svg = svgString(tester);
    expect(
      svg.contains('M264 554L270 553'),
      isFalse,
      reason: 'центральный осколок между бёдрами должен быть удалён',
    );
    expect(
      'M196 518'.allMatches(svg).length,
      1,
      reason: 'левый квадрицепс должен быть один',
    );
    expect(
      'M344 518'.allMatches(svg).length,
      1,
      reason: 'правый квадрицепс должен быть один',
    );
  });

  testWidgets(
    'родительская группа «плечи» подсвечивает дельты на обоих видах',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const MuscleDiagram(
            view: MuscleView.front,
            highlights: {'shoulders': 1.0},
          ),
        ),
      );
      // Передний вид: передняя + средняя дельта (2 пути каждая).
      expect(activeCount(tester), 4);

      await tester.pumpWidget(
        wrap(
          const MuscleDiagram(
            view: MuscleView.back,
            highlights: {'shoulders': 1.0},
          ),
        ),
      );
      // Задний вид: задняя дельта (2 пути).
      expect(activeCount(tester), 2);
    },
  );

  testWidgets(
    'родительская группа «грудь» подсвечивает все подгруппы (6 путей)',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const MuscleDiagram(
            view: MuscleView.front,
            highlights: {'chest': 1.0},
          ),
        ),
      );
      // Верх/центр/низ × 2 стороны = 6 путей.
      expect(activeCount(tester), 6);
    },
  );

  testWidgets('подгруппа «верх груди» подсвечивает только свои пути', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const MuscleDiagram(
          view: MuscleView.front,
          highlights: {'chest_upper': 1.0},
        ),
      ),
    );
    // Верх груди: 2 пути (левая и правая сторона).
    expect(activeCount(tester), 2);
  });

  testWidgets('подгруппа «низ груди» подсвечивает только свои пути', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const MuscleDiagram(
          view: MuscleView.front,
          highlights: {'chest_lower': 1.0},
        ),
      ),
    );
    expect(activeCount(tester), 2);
  });

  testWidgets('подгруппа «центр груди» подсвечивает только свои пути', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const MuscleDiagram(
          view: MuscleView.front,
          highlights: {'chest_center': 1.0},
        ),
      ),
    );
    expect(activeCount(tester), 2);
  });

  testWidgets('подсветка одной подгруппы груди не активирует соседние', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const MuscleDiagram(
          view: MuscleView.front,
          highlights: {'chest_center': 1.0},
        ),
      ),
    );

    // Активны только 2 пути центра груди, не 6 (соседние подгруппы).
    expect(activeCount(tester), 2);
  });
}
