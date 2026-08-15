import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/main.dart';

import 'helpers/test_services.dart';

void main() {
  setUp(registerTestServices);

  testWidgets('App открывается на вкладке Главная', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FitnessAppAi());
    await tester.pumpAndSettle();

    expect(find.text('Нет программ'), findsOneWidget);
  });
}
