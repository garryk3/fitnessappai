import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_form_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late ExerciseRepository repository;
  late String pickedFilePath;
  XFile? lastPicked;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('exercise_form_test');
    lastPicked = null;
    pickedFilePath = '${tempDir.path}/dummy.webp';
    await File(pickedFilePath).writeAsBytes([0, 0, 0, 0]);
    repository = ExerciseRepository(
      db,
      MediaStore(
        directoryProvider: () async => tempDir,
        assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
        filePicker: () async => lastPicked,
      ),
    );
    addTearDown(() async {
      await db.close();
      await tempDir.delete(recursive: true);
    });
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    int? exerciseId,
    ExerciseRepository? repo,
    MediaFilePicker? picker,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ExerciseFormScreen(
          exerciseId: exerciseId,
          repository: repo ?? repository,
          mediaStore: MediaStore(
            directoryProvider: () async => tempDir,
            assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
            filePicker: picker ?? () async => lastPicked,
          ),
          mediaCache: MediaCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Exercise exercise(
    String name, {
    ExerciseType type = ExerciseType.strength,
    String description = '',
    List<String> commonMistakes = const [],
    bool isCustom = true,
    bool hideOptional = false,
    String? thumbnailPath,
    String? animationPath,
  }) {
    return Exercise(
      name: name,
      type: type,
      description: description,
      commonMistakes: commonMistakes,
      isCustom: isCustom,
      hideOptional: hideOptional,
      thumbnailPath: thumbnailPath,
      animationPath: animationPath,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  Future<int> muscleId(String key) async {
    final row = await (db.select(
      db.muscleGroups,
    )..where((t) => t.key.equals(key))).getSingle();
    return row.id;
  }

  Future<int> tagId(String key) async {
    final row = await (db.select(
      db.contraindicationTags,
    )..where((t) => t.key.equals(key))).getSingle();
    return row.id;
  }

  /// Ищет [FilterChip] с подписью [chipLabel] внутри строки, содержащей [rowText].
  Finder chipInRow(String rowText, String chipLabel) => find.descendant(
    of: find.ancestor(of: find.text(rowText), matching: find.byType(Row)).first,
    matching: find.widgetWithText(FilterChip, chipLabel),
  );

  /// Скроллит список формы вниз, пока [target] не появится в дереве.
  ///
  /// Прокрутка через позицию скролла, а не через жест драга: центр списка
  /// может попадать в пустые промежутки, где hit-тест не находит скролл.
  Future<void> scrollFormTo(WidgetTester tester, Finder target) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    for (var i = 0; i < 40 && target.evaluate().isEmpty; i++) {
      position.jumpTo(position.pixels + 200);
      await tester.pump();
    }
    expect(target, findsWidgets);
    final viewportTop = tester.getTopLeft(find.byType(ListView)).dy;
    final targetTop = tester.getTopLeft(target.first).dy;
    position.jumpTo(position.pixels + (targetTop - viewportTop));
    await tester.pumpAndSettle();
  }

  /// Выбирает «Грудь → Основная» как обязательную мышцу перед сохранением.
  Future<void> selectChestMuscle(WidgetTester tester) async {
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    scrollable.position.jumpTo(0);
    await tester.pump();
    await scrollFormTo(tester, find.text('Грудь'));
    await tester.tap(chipInRow('Грудь', 'Основная'));
    await tester.pump();
  }

  testWidgets('пустое название не сохраняется', (tester) async {
    await pumpForm(tester);
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pump();

    expect(find.text('Введите название'), findsOneWidget);
    final exercises = await repository.getAll();
    expect(exercises, isEmpty);
  });

  testWidgets('поле названия отмечено звёздочкой как обязательное', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.pump();

    expect(find.text('Название *', findRichText: true), findsWidgets);
  });

  testWidgets('создаёт упражнение с мышцами и тегами', (tester) async {
    final chestId = await muscleId('chest');
    final kneesTag = await tagId('knees');

    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Название *'),
      'Жим штанги',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Описание'),
      'Классический жим',
    );

    await scrollFormTo(tester, find.text('Добавить ошибку'));
    await tester.tap(find.text('Добавить ошибку'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Отрыв таза');

    await scrollFormTo(tester, chipInRow('Грудь', 'Основная'));
    await tester.tap(chipInRow('Грудь', 'Основная'));
    await tester.pump();

    await scrollFormTo(tester, find.widgetWithText(FilterChip, 'Колени'));
    await tester.tap(find.widgetWithText(FilterChip, 'Колени'));
    await tester.pump();

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final exercises = await repository.getAll();
    expect(exercises, hasLength(1));
    final created = exercises.single;
    expect(created.name, 'Жим штанги');
    expect(created.description, 'Классический жим');
    expect(created.commonMistakes, ['Отрыв таза']);
    expect(created.isCustom, isTrue);
    expect(created.type, ExerciseType.strength);

    final muscles = await repository.getMuscles(created.id!);
    expect(muscles, hasLength(1));
    expect(muscles.single.muscleGroupId, chestId);
    expect(muscles.single.intensity, MuscleIntensity.primary);

    final tags = await repository.getContraindications(created.id!);
    expect(tags.map((t) => t.id), [kneesTag]);
  });

  testWidgets('сохранение без мышц блокируется и показывает ошибку', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Название *'),
      'Без мышц',
    );
    await scrollFormTo(tester, find.text('Задействованные мышцы'));

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Выберите хотя бы одну мышцу'), findsOneWidget);
    expect(await repository.getAll(), isEmpty);

    await tester.tap(chipInRow('Грудь', 'Основная'));
    await tester.pumpAndSettle();

    expect(find.text('Выберите хотя бы одну мышцу'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final created = (await repository.getAll()).single;
    expect(created.name, 'Без мышц');
  });

  testWidgets('выбор типа меняет тип упражнения', (tester) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Название *'),
      'Бег трусцой',
    );
    await tester.tap(find.text('Силовые'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бег').last);
    await tester.pumpAndSettle();

    await selectChestMuscle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final created = (await repository.getAll()).single;
    expect(created.type, ExerciseType.running);
  });

  testWidgets('чекбокс скрытия необязательных полей сохраняется', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Название *'),
      'Скрытое',
    );
    await scrollFormTo(
      tester,
      find.textContaining('Скрывать необязательные поля'),
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    await selectChestMuscle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final created = (await repository.getAll()).single;
    expect(created.hideOptional, isTrue);
  });

  testWidgets('редактирование восстанавливает чекбокс скрытия', (tester) async {
    final saved = await repository.create(
      exercise('Скрытое', description: 'Описание', hideOptional: true),
      const [],
    );

    await pumpForm(tester, exerciseId: saved.id);
    await scrollFormTo(
      tester,
      find.textContaining('Скрывать необязательные поля'),
    );

    final checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.value, isTrue);
  });

  testWidgets('выбор анимации сохраняет путь', (tester) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Название *'),
      'С анимацией',
    );
    await scrollFormTo(tester, find.text('Выбрать анимацию'));
    lastPicked = XFile(pickedFilePath);
    await tester.runAsync(() async {
      await tester.tap(find.text('Выбрать анимацию'));
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (find.text('Убрать анимацию').evaluate().isNotEmpty) {
          return;
        }
      }
    });
    await tester.pumpAndSettle();

    expect(find.text('Убрать анимацию'), findsOneWidget);

    await selectChestMuscle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final created = (await repository.getAll()).single;
    expect(created.animationPath, '${tempDir.path}/media/dummy.webp');
  });

  testWidgets('выбор миниатюры сохраняет путь', (tester) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Название *'),
      'С миниатюрой',
    );
    await scrollFormTo(tester, find.text('Выбрать изображение'));
    lastPicked = XFile(pickedFilePath);
    await tester.runAsync(() async {
      await tester.tap(find.text('Выбрать изображение'));
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (find.text('Убрать изображение').evaluate().isNotEmpty) {
          return;
        }
      }
    });
    await tester.pumpAndSettle();

    expect(find.text('Убрать изображение'), findsOneWidget);

    await selectChestMuscle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final created = (await repository.getAll()).single;
    expect(created.thumbnailPath, '${tempDir.path}/media/dummy.webp');
    expect(created.animationPath, isNull);
  });

  testWidgets('редактирование сохраняет thumbnail и animation раздельно', (
    tester,
  ) async {
    final saved = await repository.create(
      exercise(
        'С медиа',
        thumbnailPath: '${tempDir.path}/media/thumb.png',
        animationPath: '${tempDir.path}/media/anim.webp',
      ),
      const [],
    );

    await pumpForm(tester, exerciseId: saved.id);
    await scrollFormTo(tester, find.text('Выбрать изображение'));

    expect(find.text('Убрать изображение'), findsOneWidget);
    expect(find.text('Убрать анимацию'), findsOneWidget);

    await selectChestMuscle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final updated = await repository.getById(saved.id!);
    expect(updated!.thumbnailPath, '${tempDir.path}/media/thumb.png');
    expect(updated.animationPath, '${tempDir.path}/media/anim.webp');
  });

  testWidgets('редактирование не копирует thumbnail в animationPath', (
    tester,
  ) async {
    final saved = await repository.create(
      exercise(
        'Только миниатюра',
        thumbnailPath: '${tempDir.path}/media/thumb.png',
      ),
      const [],
    );

    await pumpForm(tester, exerciseId: saved.id);
    await tester.pumpAndSettle();

    await selectChestMuscle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final updated = await repository.getById(saved.id!);
    expect(updated!.thumbnailPath, '${tempDir.path}/media/thumb.png');
    expect(updated.animationPath, isNull);
  });

  testWidgets('редактирование сохраняет существующее упражнение', (
    tester,
  ) async {
    final created = await repository.create(exercise('Жим штанги'), const []);
    final before = await repository.getById(created.id!);

    await pumpForm(tester, exerciseId: created.id!);
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Название *'),
      'Жим штанги лёжа',
    );
    await selectChestMuscle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final updated = await repository.getById(created.id!);
    expect(updated!.name, 'Жим штанги лёжа');
    expect(updated.isCustom, before!.isCustom);
    expect(updated.createdAt, before.createdAt);
    expect(await repository.getAll(), hasLength(1));
  });

  testWidgets('подгруппы дельт выводятся под «Плечи» и сохраняются', (
    tester,
  ) async {
    final frontDeltId = await muscleId('shoulders_front');

    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Название *'),
      'Жим гантелей',
    );

    await scrollFormTo(tester, find.text('Передняя дельта'));
    expect(find.text('Плечи'), findsOneWidget);
    expect(find.text('Передняя дельта'), findsOneWidget);
    expect(find.text('Средняя дельта'), findsOneWidget);
    expect(find.text('Задняя дельта'), findsOneWidget);
    await tester.tap(chipInRow('Передняя дельта', 'Основная'));
    await tester.pump();

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final created = (await repository.getAll()).single;
    final muscles = await repository.getMuscles(created.id!);
    expect(muscles, hasLength(1));
    expect(muscles.single.muscleGroupId, frontDeltId);
    expect(muscles.single.intensity, MuscleIntensity.primary);
  });

  testWidgets('ошибка выбора анимации показывает SnackBar без краха', (
    tester,
  ) async {
    await pumpForm(
      tester,
      picker: () async => throw PlatformException(code: 'pick_failed'),
    );

    await scrollFormTo(tester, find.text('Выбрать анимацию'));
    await tester.tap(find.text('Выбрать анимацию'));
    await tester.pumpAndSettle();

    expect(
      find.text('Не удалось загрузить файл. Попробуйте ещё раз.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
