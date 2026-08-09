import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/main.dart';

void main() {
  testWidgets('App renders FitnessAppAI', (WidgetTester tester) async {
    await tester.pumpWidget(const FitnessAppAi());

    expect(find.text('FitnessAppAI'), findsOneWidget);
  });
}
