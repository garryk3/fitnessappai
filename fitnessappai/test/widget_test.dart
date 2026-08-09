import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/main.dart';

void main() {
  testWidgets('App открывается на вкладке Упражнения', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FitnessAppAi());

    expect(find.text('Раздел «Упражнения» в разработке'), findsOneWidget);
  });
}
