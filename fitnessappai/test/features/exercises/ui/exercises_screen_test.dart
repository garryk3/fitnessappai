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
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/exercises_screen.dart';
import 'package:fitnessappai/features/exercises/ui/single_exercise_params_screen.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late ExerciseRepository repository;
  late UserProfileRepository profileRepository;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('exercises_screen_test');
    repository = ExerciseRepository(
      db,
      MediaStore(
        directoryProvider: () async => tempDir,
        assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
        filePicker: (fileType) async => null,
      ),
    );
    profileRepository = UserProfileRepository(db);
    addTearDown(() async {
      await db.close();
      await tempDir.delete(recursive: true);
    });
  });

  Future<void> pumpExercises(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/exercises',
      routes: [
        GoRoute(
          path: '/exercises',
          builder: (context, state) => ExercisesScreen(
            repository: repository,
            mediaCache: MediaCache(),
            profileRepository: profileRepository,
          ),
        ),
        GoRoute(
          path: '/exercises/:id/params',
          builder: (context, state) => SingleExerciseParamsScreen(
            exerciseId: int.parse(state.pathParameters['id']!),
            exerciseRepository: repository,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Exercise exercise(
    String name, {
    ExerciseType type = ExerciseType.strength,
    String? thumbnailPath,
  }) {
    return Exercise(
      name: name,
      type: type,
      thumbnailPath: thumbnailPath,
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

  Finder searchField() => find.descendant(
    of: find.byType(SearchBar),
    matching: find.byType(TextField),
  );

  testWidgets('показывает пустое состояние', (tester) async {
    await pumpExercises(tester);

    expect(find.text('Поиск упражнений'), findsOneWidget);
    expect(find.text('Список упражнений пуст'), findsOneWidget);
  });

  testWidgets('отображает карточки упражнений с бейджами типа', (tester) async {
    await repository.create(exercise('Жим штанги'), const []);
    await repository.create(
      exercise('Бег трусцой', type: ExerciseType.running),
      const [],
    );
    await repository.create(
      exercise('Планка', type: ExerciseType.plank),
      const [],
    );
    await pumpExercises(tester);

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Бег трусцой'), findsOneWidget);
    expect(find.text('Планка'), findsOneWidget);
    expect(find.text('Силовые'), findsWidgets);
    expect(find.text('Бег'), findsWidgets);
    expect(find.text('Время'), findsWidgets);
  });

  testWidgets('поиск фильтрует список по названию', (tester) async {
    await repository.create(exercise('Жим штанги'), const []);
    await repository.create(exercise('Приседания'), const []);
    await pumpExercises(tester);

    await tester.enterText(searchField(), 'жим');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Приседания'), findsNothing);
  });

  testWidgets('фильтр по типу отображает только подходящие упражнения', (
    tester,
  ) async {
    await repository.create(exercise('Жим штанги'), const []);
    await repository.create(
      exercise('Лягушка', type: ExerciseType.plank),
      const [],
    );
    await pumpExercises(tester);

    await tester.tap(
      find.ancestor(of: find.text('Время'), matching: find.byType(FilterChip)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Лягушка'), findsOneWidget);
    expect(find.text('Жим штанги'), findsNothing);

    await tester.tap(find.text('Все'));
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Лягушка'), findsOneWidget);
  });

  testWidgets('показывает мышцы и предупреждение о противопоказаниях', (
    tester,
  ) async {
    final chestId = await muscleId('chest');
    final kneesTag = await tagId('knees');
    final created = await repository.create(exercise('Жим штанги'), [
      ExerciseMuscle(
        exerciseId: 0,
        muscleGroupId: chestId,
        intensity: MuscleIntensity.primary,
      ),
    ]);
    await repository.setContraindications(created.id!, [kneesTag]);
    await profileRepository.setContraindicationTags(['knees']);
    await pumpExercises(tester);

    expect(find.text('Грудь'), findsOneWidget);
    expect(find.text('Противопоказания'), findsOneWidget);
  });

  testWidgets('бейдж не показывается без пересечения с профилем', (
    tester,
  ) async {
    final kneesTag = await tagId('knees');
    final created = await repository.create(exercise('Жим штанги'), const []);
    await repository.setContraindications(created.id!, [kneesTag]);
    await pumpExercises(tester);

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Противопоказания'), findsNothing);
  });

  testWidgets('новое упражнение появляется без повторного открытия экрана', (
    tester,
  ) async {
    await pumpExercises(tester);
    expect(find.text('Список упражнений пуст'), findsOneWidget);

    await repository.create(exercise('Новое упражнение'), const []);

    await tester.pumpAndSettle();

    expect(find.text('Список упражнений пуст'), findsNothing);
    expect(find.text('Новое упражнение'), findsOneWidget);
  });

  testWidgets('миниатюра показывается в карточке упражнения', (tester) async {
    await repository.create(
      exercise('Жим штанги', thumbnailPath: '${tempDir.path}/media/thumb.png'),
      const [],
    );
    await repository.create(exercise('Приседания'), const []);

    await pumpExercises(tester);

    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isNotNull);
  });

  testWidgets('без медиа показывается плейсхолдер', (tester) async {
    await repository.create(exercise('Приседания'), const []);

    await pumpExercises(tester);

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
  });

  Future<void> selectExercises(WidgetTester tester, List<String> names) async {
    await tester.longPress(find.text(names.first));
    await tester.pumpAndSettle();
    for (final name in names.skip(1)) {
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }
  }

  Future<void> addToProgram(int exerciseId, String programName) async {
    final programRepo = ProgramRepository(db);
    final created = await programRepo.create(
      Program(
        name: programName,
        daysCount: 1,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0)],
    );
    final dayRow = (await programRepo.getDays(created.id!)).single;
    await programRepo.addExerciseToDay(dayRow.id!, exerciseId);
  }

  testWidgets('диалог удаления показывает число и склонение без «#»', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await repository.create(exercise('Жим штанги'), const []);
    await repository.create(exercise('Приседания'), const []);
    await repository.create(exercise('Выпады'), const []);
    await repository.create(exercise('Подтягивания'), const []);
    await repository.create(exercise('Отжимания'), const []);
    await pumpExercises(tester);

    await selectExercises(tester, [
      'Жим штанги',
      'Приседания',
      'Выпады',
      'Подтягивания',
      'Отжимания',
    ]);
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('Удалить упражнение (5)?'), findsOneWidget);
    expect(find.text('Удалить 5 упражнений?'), findsOneWidget);
    expect(find.textContaining('#'), findsNothing);
    expect(find.textContaining('Приседания → '), findsNothing);
  });

  testWidgets('диалог удаления двух упражнений склоняет корректно', (
    tester,
  ) async {
    await repository.create(exercise('Жим штанги'), const []);
    await repository.create(exercise('Приседания'), const []);
    await pumpExercises(tester);

    await selectExercises(tester, ['Жим штанги', 'Приседания']);
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('Удалить упражнение (2)?'), findsOneWidget);
    expect(find.text('Удалить 2 упражнения?'), findsOneWidget);
  });

  testWidgets('кнопка удаления заблокирована, если выбранное используется', (
    tester,
  ) async {
    final used = await repository.create(exercise('Жим штанги'), const []);
    final other = await repository.create(exercise('Приседания'), const []);
    await addToProgram(used.id!, 'Программа А');
    await pumpExercises(tester);

    await selectExercises(tester, ['Жим штанги', 'Приседания']);
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Упражнение используется в программах'),
      findsOneWidget,
    );
    expect(find.textContaining('Программа А'), findsOneWidget);
    expect(find.text('Сначала удалите его из программы.'), findsOneWidget);

    final deleteButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Удалить'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(deleteButton.onPressed, isNull);

    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(await repository.getById(used.id!), isNotNull);
    expect(await repository.getById(other.id!), isNotNull);
  });

  testWidgets(
    'кнопка удаления активна и удаляет, если ничего не используется',
    (tester) async {
      final first = await repository.create(exercise('Жим штанги'), const []);
      final second = await repository.create(exercise('Приседания'), const []);
      await pumpExercises(tester);

      await selectExercises(tester, ['Жим штанги', 'Приседания']);
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      final deleteButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Удалить'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(deleteButton.onPressed, isNotNull);

      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();

      expect(await repository.getById(first.id!), isNull);
      expect(await repository.getById(second.id!), isNull);
    },
  );

  testWidgets('иконка play показывается на карточке упражнения', (
    tester,
  ) async {
    await repository.create(exercise('Жим штанги'), const []);
    await pumpExercises(tester);

    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
  });

  testWidgets('нажатие play открывает экран параметров упражнения', (
    tester,
  ) async {
    await repository.create(exercise('Жим штанги'), const []);
    await pumpExercises(tester);

    await tester.tap(find.byIcon(Icons.play_circle_outline));
    await tester.pumpAndSettle();

    expect(find.byType(SingleExerciseParamsScreen), findsOneWidget);
    expect(find.text('Параметры упражнения'), findsOneWidget);
    expect(find.text('Жим штанги'), findsOneWidget);
  });

  testWidgets('play не показывается в режиме выбора', (tester) async {
    await repository.create(exercise('Жим штанги'), const []);
    await repository.create(exercise('Приседания'), const []);
    await pumpExercises(tester);

    await tester.longPress(find.text('Жим штанги'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_circle_outline), findsNothing);
  });
}
