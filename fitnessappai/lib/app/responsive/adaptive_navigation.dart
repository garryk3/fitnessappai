import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/l10n/app_localizations.dart';

/// Адаптивная оболочка навигации по плану 40.2:
///
/// * **>600dp** — всегда развёрнутый `NavigationRail` (все 6 пунктов) без
///   подписей и без иконки открытия;
/// * **<=600dp** — нижний `NavigationBar` из 4 пунктов (Главные,
///   Упражнения, Программы, План) с подписями плюс выезжающее слева
///   выезжающее слева меню со всеми пунктами.
///
/// Порядок вкладок единый для всех размеров экрана: нижний бар показывает
/// первые 4 пункта из того же набора, что и rail, в том же порядке.
class AdaptiveNavigation extends StatelessWidget {
  const AdaptiveNavigation({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  void _onBarDestinationSelected(int branchIndex) {
    _onDestinationSelected(branchIndex);
  }

  static const int _programsBranchIndex = 2;
  static const int _planBranchIndex = 3;

  /// 6 направлений rail-навигации в едином порядке.
  List<
    ({
      NavigationRailDestination rail,
      NavigationDestination bar,
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
        branchIndex: _planBranchIndex,
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
        final bool useRail = constraints.maxWidth > 600;
        final allDestinations = _destinations(context);

        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  destinations: [
                    for (final d in allDestinations) d.rail,
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }
        return Scaffold(
          body: navigationShell,
          drawer: _buildDrawer(context, allDestinations),
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onBarDestinationSelected,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final d in allDestinations.take(4)) d.bar,
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    List<
      ({
        NavigationRailDestination rail,
        NavigationDestination bar,
        int branchIndex,
      })
    >
    destinations,
  ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final d in destinations)
                    ListTile(
                      leading: d.rail.icon,
                      selected: d.branchIndex == navigationShell.currentIndex,
                      onTap: () {
                        Navigator.of(context).pop();
                        _onDestinationSelected(d.branchIndex);
                      },
                      title: d.rail.label,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
