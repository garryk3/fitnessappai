import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/main.dart';

import '../helpers/test_services.dart';

void main() {
  setUp(registerTestServices);

  testWidgets('MaterialApp title — «Личный тренер»', (tester) async {
    await tester.pumpWidget(const FitnessAppAi());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'Личный тренер');
  });
}
