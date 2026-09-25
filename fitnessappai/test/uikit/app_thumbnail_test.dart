import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_thumbnail.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppThumbnail', () {
    testWidgets('без image рисует плейсхолдер-иконку', (tester) async {
      await _pump(tester, const AppThumbnail());

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('с image рисует картинку нужного размера', (tester) async {
      final image = MemoryImage(Uint8List.fromList(List.filled(16, 0)));
      await _pump(tester, AppThumbnail(image: image, size: 56));

      final img = tester.widget<Image>(find.byType(Image));
      expect(img.image, image);
      expect(img.width, 56);
      expect(img.height, 56);
    });

    testWidgets('кастомный borderRadius применяется с image', (tester) async {
      await _pump(
        tester,
        AppThumbnail(
          image: MemoryImage(Uint8List.fromList(List.filled(16, 0))),
          borderRadius: BorderRadius.circular(12),
          size: 56,
        ),
      );

      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius, BorderRadius.circular(12));
    });
  });
}
