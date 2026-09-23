import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/responsive/app_breakpoints.dart';
import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/app/widgets/profile_avatar.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Адаптивная оболочка навигации.
///
/// * **expanded (>=840dp)** — `NavigationRail` со всеми 6 пунктами. Иконка
///   меню в `leading` переключает состояние: сжатый (только иконки, 80dp) /
///   расширенный (иконки + подписи, 256dp), см. `_railExtended`.
/// * **compact/medium (<840dp)** — нижний `NavigationBar` из 4 пунктов
///   (Главные, Упражнения, Программы, План) с подписями плюс выезжающее
///   слева меню со всеми пунктами. Иконка вызова меню — `AppMenuButton`
///   в левом верхнем углу каждого экрана.
///
/// Порядок вкладок единый для всех размеров экрана: нижний бар показывает
/// первые 4 пункта из того же набора, что и rail, в том же порядке.
class AdaptiveNavigation extends StatefulWidget {
  const AdaptiveNavigation({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AdaptiveNavigation> createState() => _AdaptiveNavigationState();
}

class _AdaptiveNavigationState extends State<AdaptiveNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _railExtended = false;

  static const int _programsBranchIndex = 2;
  static const int _planBranchIndex = 3;

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  void _onDestinationSelected(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  void _onBarDestinationSelected(int branchIndex) {
    _onDestinationSelected(branchIndex);
  }

  void _toggleRailExtended() {
    setState(() => _railExtended = !_railExtended);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

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
          icon: const ProfileAvatar(),
          selectedIcon: const ProfileAvatar(),
          label: l10n.navProfile,
        ),
        rail: NavigationRailDestination(
          icon: const ProfileAvatar(),
          selectedIcon: const ProfileAvatar(),
          label: Text(l10n.navProfile),
        ),
      ),
    ];
  }

  Widget _buildRailLeading() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: IconButton(
        icon: Icon(_railExtended ? Icons.menu_open : Icons.menu),
        tooltip: _railExtended ? l10n.navRailCollapse : l10n.navRailExpand,
        onPressed: _toggleRailExtended,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useRail = AppBreakpoints.isExpanded(constraints.maxWidth);
        final allDestinations = _destinations(context);

        final child = useRail
            ? Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: navigationShell.currentIndex,
                      onDestinationSelected: _onDestinationSelected,
                      leading: _buildRailLeading(),
                      extended: _railExtended,
                      destinations: [for (final d in allDestinations) d.rail],
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(child: navigationShell),
                  ],
                ),
              )
            : Scaffold(
                key: _scaffoldKey,
                body: navigationShell,
                drawer: _buildDrawer(context, allDestinations),
                bottomNavigationBar: NavigationBar(
                  // Бар из 4 вкладок: пункты «Прогресс»/«Профиль» (индексы 4/5)
                  // доступны только через меню — им временно подставляется
                  // последняя доступная вкладка «План», чтобы selectedIndex не
                  // выходил за пределы destinations (иначе NavigationBar
                  // бросает assertion).
                  selectedIndex: navigationShell.currentIndex > 3
                      ? 3
                      : navigationShell.currentIndex,
                  onDestinationSelected: _onBarDestinationSelected,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (final d in allDestinations.take(4)) d.bar,
                  ],
                ),
              );

        return MenuOpener(
          onOpenMenu: useRail ? _toggleRailExtended : _openDrawer,
          child: child,
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
            // Шапка меню: аватар, тап открывает Профиль (TC-025).
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _onDestinationSelected(5);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: ProfileAvatar(radius: 28)),
              ),
            ),
            const Divider(height: 1),
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
