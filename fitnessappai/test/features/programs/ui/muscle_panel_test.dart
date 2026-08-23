import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/domain/models/muscle_group.dart';
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

  testWidgets('подгруппы не отображаются в «Не задействованы»', (
    tester,
  ) async {
    final groups = [
      group('shoulders'),
      group('shoulders_front', parentKey: 'shoulders'),
      group('chest'),
      group('quads'),
    ];

    await tester.pumpWidget(
      wrap(
        MusclePanel(
          highlights: {},
          allMuscleGroups: groups,
          title: 'Мышцы',
        ),
      ),
    );

    expect(find.text('Не задействованы'), findsOneWidget);
    expect(find.text('shoulders'), findsOneWidget);
    expect(find.text('chest'), findsOneWidget);
    expect(find.text('quads'), findsOneWidget);
    expect(find.text('shoulders_front'), findsNothing);
  });

  testWidgets('все группы задействованы — секция скрыта', (tester) async {
    final groups = [
      group('chest'),
      group('quads'),
    ];

    await tester.pumpWidget(
      wrap(
        MusclePanel(
          highlights: {'chest': 1.0, 'quads': 0.5},
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
          highlights: {'chest': 1.0, 'shoulders': 0.5},
          allMuscleGroups: groups,
          title: 'Мышцы',
        ),
      ),
    );

    expect(find.text('Не задействованы'), findsNothing);
  });
}
