import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/responsive/adaptive_navigation.dart';
import 'package:fitnessappai/app/screens/not_found_screen.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_detail_screen.dart';
import 'package:fitnessappai/features/exercises/ui/exercise_form_screen.dart';
import 'package:fitnessappai/app/bootstrap.dart';
import 'package:fitnessappai/features/exercises/ui/exercises_screen.dart';
import 'package:fitnessappai/features/exercises/ui/single_exercise_params_screen.dart';
import 'package:fitnessappai/features/home/ui/home_screen.dart';
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
import 'package:fitnessappai/features/settings/ui/settings_screen.dart';
import 'package:fitnessappai/features/workout/domain/workout_checkpoint.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_screen.dart';
import 'package:fitnessappai/features/workout/ui/workout_prepare_screen.dart';
import 'package:fitnessappai/features/workout/ui/workout_run_screen.dart';
import 'package:fitnessappai/features/workout/ui/workout_warmup_screen.dart';
import 'package:fitnessappai/core/domain/models/single_exercise_params.dart';
import 'package:fitnessappai/core/domain/models/workout_session.dart';

/// Конфигурация маршрутов приложения.
class AppRouter {
  /// Если передан [initialCheckpoint], роутер перенаправит на `/workout/run`
  /// для восстановления тренировки после сбоя/блокировки экрана.
  /// По умолчанию читает [restoredCheckpoint] из [bootstrap].
  static GoRouter create({WorkoutCheckpoint? initialCheckpoint}) {
    final checkpoint = initialCheckpoint ?? restoredCheckpoint;
    return GoRouter(
      initialLocation: '/home',
      errorBuilder: (context, state) => const NotFoundScreen(),
      redirect: checkpoint != null
          ? (context, state) {
              if (state.matchedLocation == '/workout/run') return null;
              return '/workout/run?programDayId=${checkpoint.programDayId}';
            }
          : null,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AdaptiveNavigation(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
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
          path: '/exercises/:id/params',
          builder: (context, state) => SingleExerciseParamsScreen(
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
          path: '/workout/warmup',
          builder: (context, state) {
            final dayId =
                int.tryParse(state.uri.queryParameters['programDayId'] ?? '') ??
                -1;
            final seconds =
                int.tryParse(state.uri.queryParameters['seconds'] ?? '') ?? 0;
            final variant =
                state.uri.queryParameters['variant'] == 'alternative'
                ? WorkoutVariant.alternative
                : WorkoutVariant.main;
            return WorkoutWarmupScreen(
              programDayId: dayId,
              warmupSeconds: seconds,
              variant: variant,
            );
          },
        ),
        GoRoute(
          path: '/workout/run',
          builder: (context, state) {
            final dayId = int.tryParse(
              state.uri.queryParameters['programDayId'] ?? '',
            );
            final exerciseId = int.tryParse(
              state.uri.queryParameters['exerciseId'] ?? '',
            );
            final variant =
                state.uri.queryParameters['variant'] == 'alternative'
                ? WorkoutVariant.alternative
                : WorkoutVariant.main;
            final qp = state.uri.queryParameters;
            return WorkoutRunScreen(
              programDayId: dayId,
              variant: dayId != null ? variant : null,
              exerciseId: exerciseId,
              singleExerciseParams: SingleExerciseParams(
                sets: int.tryParse(qp['sets'] ?? ''),
                reps: int.tryParse(qp['reps'] ?? ''),
                weightKg: double.tryParse(qp['weightKg'] ?? ''),
                durationSeconds: int.tryParse(qp['durationSeconds'] ?? ''),
                distanceMeters: double.tryParse(qp['distanceMeters'] ?? ''),
                restSeconds: int.tryParse(qp['restSeconds'] ?? ''),
              ),
            );
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
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
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
