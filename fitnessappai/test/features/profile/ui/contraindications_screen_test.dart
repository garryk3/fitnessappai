import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/profile/ui/contraindications_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late UserProfileRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = UserProfileRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ContraindicationsScreen(profileRepository: repo),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('показывает каталог тегов с описаниями', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Моё здоровье'), findsOneWidget);
    for (final label in [
      'Колени',
      'Спина',
      'Шея',
      'Плечи',
      'Локти',
      'Запястья',
      'Сердечно-сосудистые',
      'Беременность',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Избегайте приседаний и прыжков.'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(8));
    expect(find.byType(Switch), findsNWidgets(8));
  });

  testWidgets('восстанавливает сохранённые теги', (tester) async {
    await repo.setContraindicationTags(['knees', 'back']);

    await pumpScreen(tester);

    final switches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .toList();
    final valueByTitle = {
      for (final tile in switches) (tile.title as Text).data: tile.value,
    };
    expect(valueByTitle['Колени'], isTrue);
    expect(valueByTitle['Спина'], isTrue);
    expect(valueByTitle['Шея'], isFalse);
  });

  testWidgets('сохранение записывает выбранные теги', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Колени'));
    await tester.pump();
    await tester.tap(find.text('Беременность'));
    await tester.pump();

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Моё здоровье'), findsNothing);
    expect(find.text('Настройки сохранены'), findsOneWidget);
    final saved = await repo.getContraindicationTags();
    expect(saved.map((t) => t.key), ['knees', 'pregnancy']);
  });

  testWidgets('отключение тега убирает его из сохранённых', (tester) async {
    await repo.setContraindicationTags(['knees', 'heart']);

    await pumpScreen(tester);

    await tester.tap(find.text('Колени'));
    await tester.pump();

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    final saved = await repo.getContraindicationTags();
    expect(saved.map((t) => t.key), ['heart']);
  });
}
