import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_muscle.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/media/media_cache.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/exercises_screen.dart';
import 'package:fitnessappai/features/profile/domain/user_profile_repository.dart';
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
        filePicker: () async => null,
      ),
    );
    profileRepository = UserProfileRepository(db);
    addTearDown(() async {
      await db.close();
      await tempDir.delete(recursive: true);
    });
  });

  Future<void> pumpExercises(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ExercisesScreen(
          repository: repository,
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
    await pumpExercises(tester);

    expect(find.text('Жим штанги'), findsOneWidget);
    expect(find.text('Бег трусцой'), findsOneWidget);
    expect(find.text('Силовые'), findsWidgets);
    expect(find.text('Бег'), findsWidgets);
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
      find.ancestor(of: find.text('Планка'), matching: find.byType(FilterChip)),
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
}
