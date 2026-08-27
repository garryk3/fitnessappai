import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/responsive/app_breakpoints.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Адаптивная оболочка: на широких экранах — NavigationRail,
/// на узких — NavigationBar. Порядок вкладок и набор иконок одинаковые
/// для всех размеров экрана.
class AdaptiveNavigation extends StatelessWidget {
  const AdaptiveNavigation({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  static const int _programsBranchIndex = 2;

  List<
    ({
      NavigationDestination bar,
      NavigationRailDestination rail,
      int branchIndex,
    })
  >
  _destinations(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      (
        branchIndex: 0,
        bar: NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.navHome,
        ),
        rail: NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: Text(l10n.navHome),
        ),
      ),
      (
        branchIndex: 1,
        bar: NavigationDestination(
          icon: const Icon(Icons.fitness_center_outlined),
          selectedIcon: const Icon(Icons.fitness_center),
          label: l10n.navExercises,
        ),
        rail: NavigationRailDestination(
          icon: const Icon(Icons.fitness_center_outlined),
          selectedIcon: const Icon(Icons.fitness_center),
          label: Text(l10n.navExercises),
        ),
      ),
      (
        branchIndex: _programsBranchIndex,
        bar: NavigationDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month),
          label: l10n.navPrograms,
        ),
        rail: NavigationRailDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month),
          label: Text(l10n.navPrograms),
        ),
      ),
      (
        branchIndex: 3,
        bar: NavigationDestination(
          icon: const Icon(Icons.event_note_outlined),
          selectedIcon: const Icon(Icons.event_note),
          label: l10n.navPlan,
        ),
        rail: NavigationRailDestination(
          icon: const Icon(Icons.event_note_outlined),
          selectedIcon: const Icon(Icons.event_note),
          label: Text(l10n.navPlan),
        ),
      ),
      (
        branchIndex: 4,
        bar: NavigationDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart),
          label: l10n.navProgress,
        ),
        rail: NavigationRailDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart),
          label: Text(l10n.navProgress),
        ),
      ),
      (
        branchIndex: 5,
        bar: NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n.navProfile,
        ),
        rail: NavigationRailDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: Text(l10n.navProfile),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool expanded = AppBreakpoints.isExpanded(constraints.maxWidth);
        final allDestinations = _destinations(context);

        if (expanded) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  destinations: allDestinations.map((d) => d.rail).toList(),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (uiIndex) {
              _onDestinationSelected(allDestinations[uiIndex].branchIndex);
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            destinations: [for (final d in allDestinations) d.bar],
          ),
        );
      },
    );
  }
}
