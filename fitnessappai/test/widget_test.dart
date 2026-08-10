import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/main.dart';

import 'helpers/test_services.dart';

void main() {
  setUp(registerTestServices);

  testWidgets('App открывается на вкладке Упражнения', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FitnessAppAi());

    expect(find.text('Поиск упражнений'), findsOneWidget);
  });
}
