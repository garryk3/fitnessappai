// ignore_for_file: type=lint
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/localization_delegates.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/main.dart';

import '../../helpers/test_services.dart';

void main() {
  setUp(registerTestServices);

  testWidgets('приложение отображает русские строки', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FitnessAppAi());
    await tester.pumpAndSettle();

    expect(find.text('Главная'), findsWidgets);
    expect(find.text('Нет программ'), findsOneWidget);
  });

  testWidgets('delegates и supportedLocales настроены', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FitnessAppAi());

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.locale, const Locale('ru'));
    expect(app.supportedLocales, const [Locale('ru')]);
    // 62.1: делегаты Material/Cupertino/Widgets — из material_ui.
    expect(app.localizationsDelegates, appLocalizationsDelegates);
    expect(app.localizationsDelegates, contains(AppLocalizations.delegate));
    expect(
      app.localizationsDelegates,
      contains(GlobalMaterialLocalizations.delegate),
    );
  });

  test('AppLocalizations содержит русские значения', () async {
    expect(AppLocalizations.supportedLocales, const [Locale('ru')]);

    final AppLocalizations l10n = await AppLocalizations.delegate.load(
      const Locale('ru'),
    );
    expect(l10n.navExercises, 'Упражнения');
    expect(l10n.navPlan, 'План');
    expect(l10n.exerciseTypeStrength, 'Силовые');
    expect(l10n.schedulePerformed, 'Выполнено');
    expect(l10n.muscleAbs, 'Пресс');
  });
}
