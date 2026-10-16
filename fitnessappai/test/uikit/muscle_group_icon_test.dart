// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/muscle_group_icon.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('MuscleGroupIcon.assetPathFor', () {
    test('известные ключи маппятся на свои ассеты', () {
      expect(MuscleGroupIcon.assetPathFor('arms'), endsWith('arm.jpg'));
      expect(MuscleGroupIcon.assetPathFor('back'), endsWith('back.jpg'));
      expect(MuscleGroupIcon.assetPathFor('legs'), endsWith('legs.jpg'));
      expect(
        MuscleGroupIcon.assetPathFor('shoulders'),
        endsWith('shoulder.jpg'),
      );
      expect(MuscleGroupIcon.assetPathFor('chest'), endsWith('press.jpg'));
      expect(MuscleGroupIcon.assetPathFor('abs'), endsWith('press.jpg'));
      expect(MuscleGroupIcon.assetPathFor('neck'), endsWith('neck.jpg'));
    });

    test('неизвестный ключ маппится на rest', () {
      expect(MuscleGroupIcon.assetPathFor('__unknown__'), endsWith('rest.jpg'));
    });
  });

  group('MuscleGroupIcon.dedupeByAsset', () {
    test('грудь и пресс — один ассет, порядок сохраняется (54.5)', () {
      expect(MuscleGroupIcon.dedupeByAsset(['chest', 'abs', 'arms', 'chest']), [
        'chest',
        'arms',
      ]);
    });

    test('пустой список — пустой результат', () {
      expect(MuscleGroupIcon.dedupeByAsset(const []), isEmpty);
    });
  });

  group('MuscleGroupIcon', () {
    testWidgets('рендерит Image с ассетом группы', (tester) async {
      await _pump(tester, const MuscleGroupIcon(muscleKey: 'arms', size: 24));

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, endsWith('arm.jpg'));
    });
  });
}
