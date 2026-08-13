import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/exercise_type.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/programs/ui/programs_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository repository;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repository = ProgramRepository(db);
    addTearDown(() => db.close());
  });

  Future<void> pumpPrograms(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: ProgramsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
  }

  Program program(String name, {int daysCount = 1}) {
    return Program(
      name: name,
      daysCount: daysCount,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  Future<int> insertExercise() async {
    return db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: 'Жим штанги',
            type: ExerciseType.strength,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        );
  }

  testWidgets('показывает пустое состояние', (tester) async {
    await pumpPrograms(tester);

    expect(find.text('Программы'), findsOneWidget);
    expect(find.text('Список программ пуст'), findsOneWidget);
  });

  testWidgets('отображает карточки программ с днями и счётчиками', (
    tester,
  ) async {
    final created = await repository.create(program('Сплит', daysCount: 3), [
      ProgramDay(programId: 0, dayIndex: 0, dayOfWeek: 1),
      ProgramDay(programId: 0, dayIndex: 1, dayOfWeek: 4),
      ProgramDay(programId: 0, dayIndex: 2),
    ]);
    final exId = await insertExercise();
    final days = await repository.getDays(created.id!);
    await repository.addExerciseToDay(days.first.id!, exId);

    await pumpPrograms(tester);

    expect(find.text('Сплит'), findsOneWidget);
    expect(find.text('3 дня'), findsOneWidget);
    expect(find.text('Пн'), findsOneWidget);
    expect(find.text('Чт'), findsOneWidget);
    expect(find.text('1 упражнение'), findsOneWidget);
  });

  testWidgets('удаление с подтверждением убирает программу', (tester) async {
    await repository.create(program('Full Body'), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    await pumpPrograms(tester);

    expect(find.text('Full Body'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(PopupMenuButton<String>),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('Удалить программу «Full Body»?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('Full Body'), findsNothing);
    expect(find.text('Список программ пуст'), findsOneWidget);
  });

  testWidgets('отмена удаления сохраняет программу', (tester) async {
    await repository.create(program('Сплит'), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    await pumpPrograms(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(PopupMenuButton<String>),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Отмена'));
    await tester.pumpAndSettle();

    expect(find.text('Сплит'), findsOneWidget);
  });

  testWidgets('новая программа появляется без повторного открытия экрана', (
    tester,
  ) async {
    await pumpPrograms(tester);
    expect(find.text('Список программ пуст'), findsOneWidget);

    await repository.create(program('Сплит'), [
      ProgramDay(programId: 0, dayIndex: 0),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Список программ пуст'), findsNothing);
    expect(find.text('Сплит'), findsOneWidget);
  });
}
