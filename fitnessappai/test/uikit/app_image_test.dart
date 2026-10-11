import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_image.dart';

Widget _errorBuilder(BuildContext context, Object error, StackTrace? stack) =>
    const Text('Ошибка');

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('AppImage', () {
    testWidgets('рендерит Image с errorBuilder по умолчанию и центрированием', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppImage(image: NetworkImage('https://example.com/a.png')),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.errorBuilder, isNotNull);
      expect(image.alignment, Alignment.center);
    });

    testWidgets('передаёт кастомный errorBuilder', (tester) async {
      await _pump(
        tester,
        const AppImage(
          image: NetworkImage('https://example.com/a.png'),
          errorBuilder: _errorBuilder,
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.errorBuilder, same(_errorBuilder));
    });

    testWidgets('cacheWidth оборачивает провайдер в ResizeImage', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppImage(
          image: NetworkImage('https://example.com/a.png'),
          cacheWidth: 64,
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<ResizeImage>());
    });
  });
}
