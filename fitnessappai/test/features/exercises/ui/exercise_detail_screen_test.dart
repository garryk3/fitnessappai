import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_detail_screen.dart';
import 'package:fitnessappai/features/exercises/ui/muscle_diagram.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late ExerciseRepository repository;
  late UserProfileRepository profileRepository;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('exercise_detail_test');
    repository = ExerciseRepository(
      db,
      MediaStore(
        directoryProvider: () async => tempDir,
        assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
        filePicker: () async => null,
      ),
    );
    profileRepository = UserProfileRepository(db);
    addTearDown(() async {
      await db.close();
      await tempDir.delete(recursive: true);
    });
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    required int exerciseId,
    ExerciseRepository? repo,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ExerciseDetailScreen(
          key: UniqueKey(),
          exerciseId: exerciseId,
          repository: repo ?? repository,
          mediaCache: MediaCache(),
          profileRepository: profileRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Exercise exercise(
    String name, {
    ExerciseType type = ExerciseType.strength,
    String description = '',
    String instructions = '',
    List<String> commonMistakes = const [],
    bool isCustom = false,
    bool hideOptional = false,
  }) {
    return Exercise(
      name: name,
      type: type,
      description: description,
      instructions: instructions,
      commonMistakes: commonMistakes,
      isCustom: isCustom,
      hideOptional: hideOptional,
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

  testWidgets('показывает все секции полного упражнения', (tester) async {
    final chestId = await muscleId('chest');
    final kneesTag = await tagId('knees');
    final created = await repository.create(
      exercise(
        'Жим штанги',
        description: 'Классический жим',
        instructions: '1. Лягте. 2. Выжмите.',
        commonMistakes: ['Отрыв таза'],
      ),
      [
        ExerciseMuscle(
          exerciseId: 0,
          muscleGroupId: chestId,
          intensity: MuscleIntensity.primary,
        ),
      ],
    );
    await repository.setContraindications(created.id!, [kneesTag]);

    await pumpDetail(tester, exerciseId: created.id!);

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Силовые'), findsOneWidget);
    expect(find.text('Описание'), findsOneWidget);
    expect(find.text('Классический жим'), findsOneWidget);
    expect(find.text('Техника выполнения'), findsOneWidget);
    expect(find.text('1. Лягте. 2. Выжмите.'), findsOneWidget);
    expect(find.text('Частые ошибки'), findsOneWidget);
    expect(find.text('Отрыв таза'), findsOneWidget);
    expect(find.text('Задействованные мышцы'), findsOneWidget);
    expect(find.text('Грудь'), findsOneWidget);
    expect(find.byType(MuscleDiagram), findsNWidgets(2));

    await tester.scrollUntilVisible(find.text('Противопоказания'), 200);

    expect(find.text('Противопоказания'), findsOneWidget);
    expect(find.text('Колени'), findsOneWidget);
  });

  testWidgets('скрывает секции при включённом hideOptional', (tester) async {
    final created = await repository.create(
      exercise(
        'Жим штанги',
        description: 'Классический жим',
        instructions: '1. Лягте. 2. Выжмите.',
        commonMistakes: ['Отрыв таза'],
        hideOptional: true,
      ),
      const [],
    );

    await pumpDetail(tester, exerciseId: created.id!);

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Описание'), findsNothing);
    expect(find.text('Классический жим'), findsNothing);
    expect(find.text('Техника выполнения'), findsNothing);
    expect(find.text('Частые ошибки'), findsNothing);
    expect(find.text('Отрыв таза'), findsNothing);
  });

  testWidgets('подсвечивает противопоказания, пересекающиеся с профилем', (
    tester,
  ) async {
    final kneesTag = await tagId('knees');
    final backTag = await tagId('back');
    final created = await repository.create(exercise('Приседания'), const []);
    await repository.setContraindications(created.id!, [kneesTag, backTag]);
    await profileRepository.setContraindicationTags(['knees']);

    await pumpDetail(tester, exerciseId: created.id!);
    await tester.scrollUntilVisible(find.text('Противопоказания'), 200);

    expect(find.text('Есть противопоказания для вас'), findsOneWidget);
    expect(find.text('Колени'), findsOneWidget);
    expect(find.text('Спина'), findsOneWidget);
  });

  testWidgets('секция противопоказаний без предупреждения без профиля', (
    tester,
  ) async {
    final kneesTag = await tagId('knees');
    final created = await repository.create(exercise('Приседания'), const []);
    await repository.setContraindications(created.id!, [kneesTag]);

    await pumpDetail(tester, exerciseId: created.id!);
    await tester.scrollUntilVisible(find.text('Противопоказания'), 200);

    expect(find.text('Есть противопоказания для вас'), findsNothing);
    expect(find.text('Колени'), findsOneWidget);
  });

  testWidgets('скрывает секции при отсутствии данных', (tester) async {
    final created = await repository.create(exercise('Планка'), const []);

    await pumpDetail(tester, exerciseId: created.id!);

    expect(find.text('Планка'), findsOneWidget);
    expect(find.text('Описание'), findsNothing);
    expect(find.text('Техника выполнения'), findsNothing);
    expect(find.text('Частые ошибки'), findsNothing);
    expect(find.byType(MuscleDiagram), findsNothing);
    expect(find.text('Противопоказания'), findsNothing);
  });

  testWidgets('показывает «не найдено» для отсутствующего упражнения', (
    tester,
  ) async {
    await pumpDetail(tester, exerciseId: 999);

    expect(find.text('Упражнение не найдено'), findsOneWidget);
  });

  testWidgets('кнопки редактирования и удаления видны только для кастомных', (
    tester,
  ) async {
    final builtIn = await repository.create(exercise('Жим штанги'), const []);
    final custom = await repository.create(
      exercise('Моё упражнение', isCustom: true),
      const [],
    );

    await pumpDetail(tester, exerciseId: builtIn.id!);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);

    await pumpDetail(tester, exerciseId: custom.id!);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('удаление кастомного упражнения с подтверждением', (
    tester,
  ) async {
    final custom = await repository.create(
      exercise('Моё упражнение', isCustom: true),
      const [],
    );

    await pumpDetail(tester, exerciseId: custom.id!);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Удалить упражнение «Моё упражнение»?'), findsOneWidget);

    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(await repository.getById(custom.id!), isNull);
  });

  testWidgets('редактирование ведёт на форму', (tester) async {
    final custom = await repository.create(
      exercise('Моё упражнение', isCustom: true),
      const [],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        routerConfig: GoRouter(
          initialLocation: '/exercises/${custom.id!}',
          routes: [
            GoRoute(
              path: '/exercises/:id',
              builder: (context, state) => ExerciseDetailScreen(
                exerciseId: int.parse(state.pathParameters['id']!),
                repository: repository,
                mediaCache: MediaCache(),
                profileRepository: profileRepository,
              ),
            ),
            GoRoute(
              path: '/exercises/:id/edit',
              builder: (context, state) =>
                  const Scaffold(body: Text('EDIT_SCREEN')),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('EDIT_SCREEN'), findsOneWidget);
  });

  testWidgets('обновляется после изменения данных в БД без переоткрытия', (
    tester,
  ) async {
    final created = await repository.create(
      exercise('Приседания', description: 'Старая техника'),
      const [],
    );

    await pumpDetail(tester, exerciseId: created.id!);
    expect(find.text('Старая техника'), findsOneWidget);

    await repository.update(created.copyWith(description: 'Новая техника'));
    await tester.pumpAndSettle();

    expect(find.text('Новая техника'), findsOneWidget);
  });
}
