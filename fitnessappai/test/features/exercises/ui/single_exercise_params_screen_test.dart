import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/media/media_store.dart';
import 'package:fitnessappai/features/exercises/data/exercise_repository.dart';
import 'package:fitnessappai/features/exercises/ui/single_exercise_params_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late ExerciseRepository exerciseRepository;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp(
      'single_exercise_params_test',
    );
    exerciseRepository = ExerciseRepository(
      db,
      MediaStore(
        directoryProvider: () async => tempDir,
        assetLoader: (path) async => Uint8List.fromList([1, 2, 3]),
        filePicker: (fileType) async => null,
      ),
    );
    addTearDown(() async {
      await db.close();
      await tempDir.delete(recursive: true);
    });
  });

  Future<Exercise> createExercise(String name, ExerciseType type) {
    return exerciseRepository.create(
      Exercise(
        name: name,
        type: type,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      const [],
    );
  }

  Future<void> pumpParams(
    WidgetTester tester,
    int exerciseId, {
    VoidCallback? onStart,
  }) async {
    final router = GoRouter(
      initialLocation: '/exercises/$exerciseId/params',
      routes: [
        GoRoute(
          path: '/exercises/:id/params',
          builder: (context, state) => SingleExerciseParamsScreen(
            exerciseId: int.parse(state.pathParameters['id']!),
            exerciseRepository: exerciseRepository,
          ),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) {
            onStart?.call();
            return const Scaffold(body: Text('workout run'));
          },
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

  Future<void> enterField(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    await tester.enterText(find.widgetWithText(TextFormField, label), value);
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('strength: набор полей по типу', (tester) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);

    await pumpParams(tester, exercise.id!);

    expect(field('Подходы'), findsOneWidget);
    expect(field('Повторения'), findsOneWidget);
    expect(field('Вес (кг)'), findsOneWidget);
    expect(field('Отдых (сек)'), findsOneWidget);
    expect(field('Время (сек)'), findsNothing);
    expect(field('Время (мин)'), findsNothing);
    expect(field('Дистанция (км)'), findsNothing);
    expect(find.text('Жим штанги'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Начать тренировку'),
      findsOneWidget,
    );
  });

  testWidgets('plank: набор полей по типу', (tester) async {
    final exercise = await createExercise('Планка', ExerciseType.plank);

    await pumpParams(tester, exercise.id!);

    expect(field('Подходы'), findsOneWidget);
    expect(field('Время (сек)'), findsOneWidget);
    expect(field('Отдых (сек)'), findsOneWidget);
    expect(field('Повторения'), findsNothing);
    expect(field('Вес (кг)'), findsNothing);
    expect(find.text('Пусто — время удержания со счётчика'), findsOneWidget);
  });

  testWidgets('running: набор полей по типу', (tester) async {
    final exercise = await createExercise('Бег', ExerciseType.running);

    await pumpParams(tester, exercise.id!);

    expect(field('Время (мин)'), findsOneWidget);
    expect(field('Дистанция (км)'), findsOneWidget);
    expect(field('Отдых (сек)'), findsOneWidget);
    expect(field('Подходы'), findsNothing);
    expect(field('Повторения'), findsNothing);
  });

  testWidgets('bodyweight: набор полей по типу', (tester) async {
    final exercise = await createExercise('Отжимания', ExerciseType.bodyweight);

    await pumpParams(tester, exercise.id!);

    expect(field('Подходы'), findsOneWidget);
    expect(field('Повторения'), findsOneWidget);
    expect(field('Отдых (сек)'), findsOneWidget);
    expect(field('Вес (кг)'), findsNothing);
    expect(field('Время (сек)'), findsNothing);
  });

  testWidgets('старт strength передаёт параметры в query', (tester) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);

    Uri? navigatedUri;
    final router = GoRouter(
      initialLocation: '/exercises/${exercise.id}/params',
      routes: [
        GoRoute(
          path: '/exercises/:id/params',
          builder: (context, state) => SingleExerciseParamsScreen(
            exerciseId: int.parse(state.pathParameters['id']!),
            exerciseRepository: exerciseRepository,
          ),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) {
            navigatedUri = state.uri;
            return const Scaffold(body: Text('workout run'));
          },
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

    await enterField(tester, 'Подходы', '4');
    await enterField(tester, 'Повторения', '8');
    await enterField(tester, 'Вес (кг)', '20.5');
    await enterField(tester, 'Отдых (сек)', '90');
    await tester.tap(find.widgetWithText(FilledButton, 'Начать тренировку'));
    await tester.pumpAndSettle();

    final qp = navigatedUri!.queryParameters;
    expect(qp['exerciseId'], '${exercise.id}');
    expect(qp['sets'], '4');
    expect(qp['reps'], '8');
    expect(qp['weightKg'], '20.5');
    expect(qp['restSeconds'], '90');
    expect(find.text('workout run'), findsOneWidget);
  });

  testWidgets('старт running конвертирует минуты и километры', (tester) async {
    final exercise = await createExercise('Бег', ExerciseType.running);

    Uri? navigatedUri;
    final router = GoRouter(
      initialLocation: '/exercises/${exercise.id}/params',
      routes: [
        GoRoute(
          path: '/exercises/:id/params',
          builder: (context, state) => SingleExerciseParamsScreen(
            exerciseId: int.parse(state.pathParameters['id']!),
            exerciseRepository: exerciseRepository,
          ),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) {
            navigatedUri = state.uri;
            return const Scaffold(body: Text('workout run'));
          },
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

    await enterField(tester, 'Время (мин)', '30');
    await enterField(tester, 'Дистанция (км)', '5');
    await enterField(tester, 'Отдых (сек)', '60');
    await tester.tap(find.widgetWithText(FilledButton, 'Начать тренировку'));
    await tester.pumpAndSettle();

    final qp = navigatedUri!.queryParameters;
    expect(qp['sets'], '1');
    expect(qp['durationSeconds'], '1800');
    expect(qp['distanceMeters'], '5000.0');
    expect(qp['restSeconds'], '60');
  });

  testWidgets('валидация: пустые обязательные поля блокируют старт', (
    tester,
  ) async {
    final exercise = await createExercise('Жим штанги', ExerciseType.strength);

    var started = false;
    await pumpParams(tester, exercise.id!, onStart: () => started = true);

    await tester.tap(find.widgetWithText(FilledButton, 'Начать тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('Заполните поле'), findsNWidgets(2));
    expect(started, isFalse);
  });

  testWidgets('планка: пустое время разрешено (счётчик удержания)', (
    tester,
  ) async {
    final exercise = await createExercise('Планка', ExerciseType.plank);

    Uri? navigatedUri;
    final router = GoRouter(
      initialLocation: '/exercises/${exercise.id}/params',
      routes: [
        GoRoute(
          path: '/exercises/:id/params',
          builder: (context, state) => SingleExerciseParamsScreen(
            exerciseId: int.parse(state.pathParameters['id']!),
            exerciseRepository: exerciseRepository,
          ),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) {
            navigatedUri = state.uri;
            return const Scaffold(body: Text('workout run'));
          },
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

    await enterField(tester, 'Подходы', '3');
    await enterField(tester, 'Отдых (сек)', '60');
    await tester.tap(find.widgetWithText(FilledButton, 'Начать тренировку'));
    await tester.pumpAndSettle();

    final qp = navigatedUri!.queryParameters;
    expect(qp['durationSeconds'], isNull);
    expect(qp['sets'], '3');
  });

  testWidgets('несуществующее упражнение показывает ошибку', (tester) async {
    await pumpParams(tester, 999);

    expect(find.text('Упражнение не найдено'), findsOneWidget);
  });
}
