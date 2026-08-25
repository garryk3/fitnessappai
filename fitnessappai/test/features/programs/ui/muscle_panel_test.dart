import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
import 'package:fitnessappai/features/progress/domain/stats_aggregator.dart';
import 'package:fitnessappai/features/programs/ui/muscle_panel.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  MuscleGroup group(String key, {String? parentKey}) => MuscleGroup(
    key: key,
    labelRu: key,
    view: MuscleView.front,
    regionKey: key,
    parentKey: parentKey,
  );

  MuscleGroupLoad load(
    MuscleGroup muscleGroup, {
    double percent = 50,
    List<MuscleGroupLoad> children = const [],
  }) => MuscleGroupLoad(
    muscleGroup: muscleGroup,
    percent: percent,
    children: children,
  );

  testWidgets('подгруппы не отображаются в «Не задействованы»', (tester) async {
    final groups = [
      group('shoulders'),
      group('shoulders_front', parentKey: 'shoulders'),
      group('chest'),
      group('quads'),
    ];

    await tester.pumpWidget(
      wrap(
        MusclePanel(loads: [], allMuscleGroups: groups, title: 'Мышцы'),
      ),
    );

    expect(find.text('Не задействованы'), findsOneWidget);
    expect(find.text('shoulders'), findsOneWidget);
    expect(find.text('chest'), findsOneWidget);
    expect(find.text('quads'), findsOneWidget);
    expect(find.text('shoulders_front'), findsNothing);
  });

  testWidgets('все группы задействованы — секция скрыта', (tester) async {
    final groups = [group('chest'), group('quads')];

    await tester.pumpWidget(
      wrap(
        MusclePanel(
          loads: [
            load(group('chest'), percent: 67),
            load(group('quads'), percent: 33),
          ],
          allMuscleGroups: groups,
          title: 'Мышцы',
        ),
      ),
    );

    expect(find.text('Задействованы'), findsOneWidget);
    expect(find.text('Не задействованы'), findsNothing);
  });

  testWidgets('только подгруппы не задействованы — секция скрыта', (
    tester,
  ) async {
    final groups = [
      group('chest'),
      group('shoulders'),
      group('shoulders_front', parentKey: 'shoulders'),
    ];

    await tester.pumpWidget(
      wrap(
        MusclePanel(
          loads: [
            load(group('chest'), percent: 67),
            load(group('shoulders'), percent: 33),
          ],
          allMuscleGroups: groups,
          title: 'Мышцы',
        ),
      ),
    );

    expect(find.text('Не задействованы'), findsNothing);
  });

  testWidgets('родительские группы отображаются жирным', (tester) async {
    final arms = group('arms');
    final biceps = group('biceps', parentKey: 'arms');

    await tester.pumpWidget(
      wrap(
        MusclePanel(
          loads: [
            load(arms, percent: 60, children: [
              load(biceps, percent: 100),
            ]),
          ],
          allMuscleGroups: [arms, biceps],
          title: 'Мышцы',
        ),
      ),
    );

    final armsText = tester.widget<Text>(find.text('arms'));
    expect(armsText.style?.fontWeight, FontWeight.w600);

    final bicepsText = tester.widget<Text>(find.text('biceps'));
    expect(bicepsText.style?.fontWeight, isNot(FontWeight.w600));
  });

  testWidgets('дети отображаются с отступом', (tester) async {
    final biceps = group('biceps', parentKey: 'arms');
    final arms = group('arms');

    await tester.pumpWidget(
      wrap(
        MusclePanel(
          loads: [
            load(arms, percent: 60, children: [
              load(biceps, percent: 100),
            ]),
          ],
          allMuscleGroups: [arms, biceps],
          title: 'Мышцы',
        ),
      ),
    );

    expect(find.text('arms'), findsOneWidget);
    expect(find.text('biceps'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('пустые loads — только заголовок и диаграмма', (tester) async {
    await tester.pumpWidget(
      wrap(
        MusclePanel(
          loads: const [],
          allMuscleGroups: const [],
          title: 'Мышцы',
        ),
      ),
    );

    expect(find.text('Мышцы'), findsOneWidget);
    expect(find.text('Задействованы'), findsNothing);
  });
}
