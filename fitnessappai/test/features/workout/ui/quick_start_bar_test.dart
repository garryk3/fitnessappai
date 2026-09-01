import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/theme/app_theme.dart';
import 'package:fitnessappai/core/database/app_database.dart';
import 'package:fitnessappai/core/domain/models/program.dart';
import 'package:fitnessappai/core/domain/models/program_day.dart';
import 'package:fitnessappai/features/programs/data/program_repository.dart';
import 'package:fitnessappai/features/workout/data/workout_repository.dart';
import 'package:fitnessappai/features/workout/ui/quick_start_bar.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_controller.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository programRepo;
  late WorkoutRepository workoutRepo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    programRepo = ProgramRepository(db);
    workoutRepo = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  WeekPlanItem item(int programDayId) => WeekPlanItem(
    programDayId: programDayId,
    dayIndex: 0,
    programName: 'База',
    dayOfWeek: 1,
    scheduledDate: DateTime(2026, 8, 10),
    status: WeekPlanStatus.pending,
  );

  Future<WeekPlanController> controller() async => WeekPlanController(
    programRepository: programRepo,
    workoutRepository: workoutRepo,
  );

  Future<int> createDay() async {
    final created = await programRepo.create(
      Program(
        name: 'База',
        daysCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isActive: true,
        activatedAt: DateTime(2024, 1, 1),
      ),
      [ProgramDay(programId: 0, dayIndex: 0)],
    );
    return (await programRepo.getDays(created.id!)).first.id!;
  }

  testWidgets('startPlannedWorkout открывает подготовку при существующем дне', (
    tester,
  ) async {
    final dayId = await createDay();
    final planController = await controller();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () =>
                      startPlannedWorkout(context, planController, item(dayId)),
                  child: const Text('Старт'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/workout/prepare/:programDayId',
          builder: (context, state) => Scaffold(
            body: Text('prepare-${state.pathParameters['programDayId']}'),
          ),
        ),
      ],
    );
    addTearDown(planController.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark(),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
      ),
    );

    await tester.tap(find.text('Старт'));
    await tester.pumpAndSettle();

    expect(find.text('prepare-$dayId'), findsOneWidget);
  });

  testWidgets('startPlannedWorkout показывает SnackBar при удалённом дне', (
    tester,
  ) async {
    final planController = await controller();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () =>
                      startPlannedWorkout(context, planController, item(999)),
                  child: const Text('Старт'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(planController.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark(),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
      ),
    );

    await tester.tap(find.text('Старт'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('День не найден'), findsOneWidget);
  });
}
