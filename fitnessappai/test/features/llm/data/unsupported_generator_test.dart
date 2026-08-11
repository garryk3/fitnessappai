import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/core/di/register_core_services.dart';
import 'package:fitnessappai/core/di/service_locator.dart';
import 'package:fitnessappai/features/llm/data/unsupported_generator.dart';
import 'package:fitnessappai/features/llm/domain/exercise_content_generator.dart';

void main() {
  test('UnsupportedGenerator.generate возвращает ошибку', () async {
    const generator = UnsupportedGenerator();

    await expectLater(generator.generate('Приседания'), throwsUnsupportedError);
  });

  test('UnsupportedGenerator зарегистрирован в ServiceLocator', () {
    final sl = ServiceLocator();
    registerCoreServices(sl);

    expect(sl.get<ExerciseContentGenerator>(), isA<UnsupportedGenerator>());
  });
}
