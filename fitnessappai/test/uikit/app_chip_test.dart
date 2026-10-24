// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_chip.dart';
import 'package:fitnessappai/uikit/app_icon.dart';
import 'package:fitnessappai/uikit/app_text.dart';

void main() {
  testWidgets('AppChip рендерит Chip с подписью, аватаром и параметрами', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppChip(
            avatar: const AppIcon(Icons.fitness_center, size: 14),
            label: const AppText('Мышцы'),
            visualDensity: VisualDensity.compact,
            backgroundColor: const Color(0xFFEEEEEE),
            shape: const StadiumBorder(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );

    expect(find.byType(Chip), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    expect(find.text('Мышцы'), findsOneWidget);
    final chip = tester.widget<Chip>(find.byType(Chip));
    expect(chip.visualDensity, VisualDensity.compact);
    expect(chip.backgroundColor, const Color(0xFFEEEEEE));
    expect(chip.shape, isA<StadiumBorder>());
    expect(chip.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
  });

  testWidgets('AppChip side: BorderSide.none — граница убрана', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppChip(label: const AppText('Тег'), side: BorderSide.none),
        ),
      ),
    );

    final chip = tester.widget<Chip>(find.byType(Chip));
    expect(chip.side, BorderSide.none);
  });
}
