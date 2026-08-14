import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/responsive/adaptive_navigation.dart';
import 'package:fitnessappai/app/screens/not_found_screen.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_detail_screen.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_form_screen.dart';
import 'package:fitnessappai/features/exercises/ui/exercises_screen.dart';
import 'package:fitnessappai/features/profile/ui/contraindications_screen.dart';
import 'package:fitnessappai/features/profile/ui/measurement_form_screen.dart';
import 'package:fitnessappai/features/profile/ui/profile_screen.dart';
import 'package:fitnessappai/features/progress/ui/day_detail_screen.dart';
import 'package:fitnessappai/features/progress/ui/exercise_progression_screen.dart';
import 'package:fitnessappai/features/progress/ui/history_screen.dart';
import 'package:fitnessappai/features/programs/ui/program_builder_screen.dart';
import 'package:fitnessappai/features/programs/ui/program_day_builder_screen.dart';
import 'package:fitnessappai/features/programs/ui/program_day_exercise_params_screen.dart';
import 'package:fitnessappai/features/programs/ui/programs_screen.dart';
import 'package:fitnessappai/features/progress/ui/progress_screen.dart';
import 'package:fitnessappai/features/sync/ui/sync_screen.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_screen.dart';
import 'package:fitnessappai/features/workout/ui/workout_prepare_screen.dart';
import 'package:fitnessappai/features/workout/ui/workout_run_screen.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';

/// Конфигурация маршрутов приложения.
class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/exercises',
      errorBuilder: (context, state) => const NotFoundScreen(),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AdaptiveNavigation(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/exercises',
                  builder: (context, state) => const ExercisesScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/programs',
                  builder: (context, state) => const ProgramsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/plan',
                  builder: (context, state) => const WeekPlanScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/progress',
                  builder: (context, state) => const ProgressScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/exercises/new',
          builder: (context, state) => const ExerciseFormScreen(),
        ),
        GoRoute(
          path: '/exercises/:id',
          builder: (context, state) => ExerciseDetailScreen(
            exerciseId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/exercises/:id/edit',
          builder: (context, state) => ExerciseFormScreen(
            exerciseId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/programs/new',
          builder: (context, state) => const ProgramBuilderScreen(),
        ),
        GoRoute(
          path: '/programs/:id/edit',
          builder: (context, state) => ProgramBuilderScreen(
            programId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/programs/:id/day/:dayIndex',
          builder: (context, state) => ProgramDayBuilderScreen(
            programId: int.parse(state.pathParameters['id']!),
            dayIndex: int.parse(state.pathParameters['dayIndex']!),
          ),
        ),
        GoRoute(
          path: '/program-day/:id/exercise-params',
          builder: (context, state) => ProgramDayExerciseParamsScreen(
            positionId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/workout/prepare/:programDayId',
          builder: (context, state) => WorkoutPrepareScreen(
            programDayId: int.parse(state.pathParameters['programDayId']!),
          ),
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) {
            final dayId =
                int.tryParse(state.uri.queryParameters['programDayId'] ?? '') ??
                -1;
            final variant =
                state.uri.queryParameters['variant'] == 'alternative'
                ? WorkoutVariant.alternative
                : WorkoutVariant.main;
            return WorkoutRunScreen(programDayId: dayId, variant: variant);
          },
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/history/:id',
          builder: (context, state) => HistoryDetailScreen(
            sessionId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
          ),
        ),
        GoRoute(
          path: '/progress/exercise/:id',
          builder: (context, state) => ExerciseProgressionScreen(
            exerciseId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
          ),
        ),
        GoRoute(
          path: '/progress/day',
          builder: (context, state) {
            final startMs =
                int.tryParse(state.uri.queryParameters['start'] ?? '') ?? 0;
            final endMs =
                int.tryParse(state.uri.queryParameters['end'] ?? '') ?? 0;
            return DayDetailScreen(
              start: DateTime.fromMillisecondsSinceEpoch(startMs),
              end: DateTime.fromMillisecondsSinceEpoch(endMs),
            );
          },
        ),
        GoRoute(path: '/sync', builder: (context, state) => const SyncScreen()),
        GoRoute(
          path: '/contraindications',
          builder: (context, state) => const ContraindicationsScreen(),
        ),
        GoRoute(
          path: '/measurements/new',
          builder: (context, state) => const MeasurementFormScreen(),
        ),
      ],
    );
  }
}
