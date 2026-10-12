// ignore_for_file: type=lint
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/uikit/app_colors.dart';

void main() {
  group('AppColors', () {
    test('transparent полностью прозрачен', () {
      expect(AppColors.transparent.a, 0);
    });
  });
}
