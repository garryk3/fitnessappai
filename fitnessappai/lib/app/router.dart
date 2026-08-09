import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/responsive/adaptive_navigation.dart';
import 'package:fitnessappai/app/screens/not_found_screen.dart';
import 'package:fitnessappai/app/screens/placeholder_screen.dart';
import 'package:fitnessappai/features/exercises/ui/exercises_screen.dart';
import 'package:fitnessappai/features/profile/ui/profile_screen.dart';
import 'package:fitnessappai/features/programs/ui/programs_screen.dart';
import 'package:fitnessappai/features/progress/ui/progress_screen.dart';
import 'package:fitnessappai/features/workout/ui/week_plan_screen.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

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
        _placeholderRoute('/exercises/new', (l10n) => l10n.exerciseNew),
        _placeholderRoute('/exercises/:id', (l10n) => l10n.exerciseDetail),
        _placeholderRoute('/exercises/:id/edit', (l10n) => l10n.exerciseEdit),
        _placeholderRoute('/programs/new', (l10n) => l10n.programNew),
        _placeholderRoute('/programs/:id/edit', (l10n) => l10n.programEdit),
        _placeholderRoute(
          '/program-day/:dayId/exercise-params',
          (l10n) => l10n.exerciseParams,
        ),
        _placeholderRoute(
          '/workout/prepare/:programDayId',
          (l10n) => l10n.workoutPrepare,
        ),
        _placeholderRoute('/workout/run', (l10n) => l10n.workoutRun),
        _placeholderRoute('/history', (l10n) => l10n.history),
        _placeholderRoute('/history/:id', (l10n) => l10n.historyDetail),
        _placeholderRoute('/sync', (l10n) => l10n.sync),
        _placeholderRoute(
          '/contraindications',
          (l10n) => l10n.contraindications,
        ),
      ],
    );
  }

  static GoRoute _placeholderRoute(
    String path,
    String Function(AppLocalizations l10n) titleBuilder,
  ) {
    return GoRoute(
      path: path,
      builder: (context, state) =>
          PlaceholderScreen(title: titleBuilder(AppLocalizations.of(context))),
    );
  }
}
