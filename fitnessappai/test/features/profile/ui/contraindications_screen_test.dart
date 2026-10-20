// ignore_for_file: type=lint
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/profile/ui/contraindications_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';
import 'package:fitnessappai/uikit/uikit.dart';

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

  testWidgets('редизайн 54.9: info-баннер и отдельная карточка на тумблер', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(
      find.text(
        'Отметьте свои противопоказания. Упражнения с ними будут '
        'отмечены предупреждением.',
      ),
      findsOneWidget,
    );
    // Отдельная карточка на каждый тумблер (8) — общей с Divider нет.
    expect(find.byType(AppCard), findsNWidgets(8));
    expect(find.byType(Divider), findsNothing);
    // Иконки-бейджи тегов.
    expect(find.byIcon(Icons.pregnant_woman), findsOneWidget);
    expect(find.byIcon(Icons.monitor_heart_outlined), findsOneWidget);
  });

  testWidgets('восстанавливает сохранённые теги', (tester) async {
    await repo.setContraindicationTags(['knees', 'back']);

    await pumpScreen(tester);

    final switches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .toList();
    final valueByTitle = {
      for (final tile in switches) (tile.title as AppText).data: tile.value,
    };
    expect(valueByTitle['Колени'], isTrue);
    expect(valueByTitle['Спина'], isTrue);
    expect(valueByTitle['Шея'], isFalse);
  });

  testWidgets('переключение свитча сохраняет теги автоматически', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Колени'));
    await tester.pumpAndSettle();
    expect(find.text('Настройки сохранены'), findsOneWidget);
    await tester.tap(find.text('Беременность'));
    await tester.pumpAndSettle();

    final saved = await repo.getContraindicationTags();
    expect(saved.map((t) => t.key), containsAll(['knees', 'pregnancy']));
  });

  testWidgets('отключение тега убирает его из сохранённых', (tester) async {
    await repo.setContraindicationTags(['knees', 'heart']);

    await pumpScreen(tester);

    await tester.tap(find.text('Колени'));
    await tester.pumpAndSettle();

    final saved = await repo.getContraindicationTags();
    expect(saved.map((t) => t.key), ['heart']);
  });
}
