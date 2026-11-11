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

  Future<void> pumpScreen(WidgetTester tester, {double textScale = 1.0}) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
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
    // 60.3: тумблеры заменены карточками — по карточке на тег.
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(AppCard), findsNWidgets(8));
    // Иконки-бейджи тегов.
    expect(find.byIcon(Icons.pregnant_woman), findsOneWidget);
    expect(find.byIcon(Icons.monitor_heart_outlined), findsOneWidget);
  });

  testWidgets('редизайн 54.9 → 60.3: info-баннер и двухколоночный grid', (
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
    // Двухколоночный grid: у GridView делегат с crossAxisCount 2.
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets(
    'fontScale 1.3: описания не режутся — extent масштабируется (60.3)',
    (tester) async {
      await pumpScreen(tester, textScale: 1.3);

      final desc = tester.getRect(find.text('Избегайте приседаний и прыжков.'));
      final card = tester.getRect(
        find
            .ancestor(
              of: find.text('Избегайте приседаний и прыжков.'),
              matching: find.byType(AppCard),
            )
            .first,
      );
      expect(desc.bottom, lessThanOrEqualTo(card.bottom));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('карточки тегов лежат в два ряда по две (60.3)', (tester) async {
    await pumpScreen(tester);

    Rect rectOf(String label) => tester.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(AppCard)).first,
    );
    final knees = rectOf('Колени');
    final back = rectOf('Спина');
    final neck = rectOf('Шея');
    // Колени и Спина — один ряд, Шея — под ними.
    expect(knees.top, back.top);
    expect(knees.left, lessThan(back.left));
    expect(neck.top, greaterThan(knees.bottom));
  });

  testWidgets('восстанавливает сохранённые теги (галки на карточках)', (
    tester,
  ) async {
    await repo.setContraindicationTags(['knees', 'back']);

    await pumpScreen(tester);

    // Выбранная карточка несёт галку check_circle; невыбранная — нет.
    bool selected(String label) => find
        .descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byType(AppCard),
          ),
          matching: find.byIcon(Icons.check_circle),
        )
        .evaluate()
        .isNotEmpty;
    expect(selected('Колени'), isTrue);
    expect(selected('Спина'), isTrue);
    expect(selected('Шея'), isFalse);
  });

  testWidgets('тап по карточке сохраняет тег автоматически', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Колени'));
    await tester.pumpAndSettle();
    // 60.3: снекбар «Настройки сохранены» убран (решение владельца).
    expect(find.text('Настройки сохранены'), findsNothing);
    await tester.tap(find.text('Беременность'));
    await tester.pumpAndSettle();

    final saved = await repo.getContraindicationTags();
    expect(saved.map((t) => t.key), containsAll(['knees', 'pregnancy']));
  });

  testWidgets('отключение тега убирает его из сохранённых', (tester) async {
    await repo.setContraindicationTags(['knees', 'heart']);

    await pumpScreen(tester);

    // «Колени» выбрана (галка есть) — тап снимает выбор.
    expect(
      find
          .descendant(
            of: find.ancestor(
              of: find.text('Колени'),
              matching: find.byType(AppCard),
            ),
            matching: find.byIcon(Icons.check_circle),
          )
          .evaluate()
          .isNotEmpty,
      isTrue,
    );
    await tester.tap(find.text('Колени'));
    await tester.pumpAndSettle();

    final saved = await repo.getContraindicationTags();
    expect(saved.map((t) => t.key), ['heart']);
  });
}
