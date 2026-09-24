import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fitnessappai/app/responsive/app_breakpoints.dart';
import 'package:fitnessappai/app/responsive/app_menu_button.dart';
import 'package:fitnessappai/app/widgets/profile_avatar.dart';
import 'package:fitnessappai/l10n/app_localizations.dart';

/// Адаптивная оболочка навигации.
///
/// * **expanded (>=840dp)** — `NavigationRail`. Свёрнутое состояние — колонка
///   иконок (80dp) с аватаром профиля среди пунктов; расширенное (256dp) —
///   открытое меню с единым дизайном для всех размеров экрана: аватар-шапка
///   (тап — Профиль) по центру, иконка сворачивания у правого края, список
///   пунктов, divider и «Настройки» у нижнего края за divider-ом.
/// * **compact/medium (<840dp)** — нижний `NavigationBar` из 4 пунктов
///   (Главные, Упражнения, Программы, План) с подписями плюс выезжающее
///   слева меню (drawer) со всеми пунктами. Иконка вызова меню —
///   `AppMenuButton` в левом верхнем углу каждого экрана.
///
/// Порядок пунктов единый для всех размеров экрана: нижний бар показывает
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
  static const int _profileBranchIndex = 5;
  static const int _historyBranchIndex = 6;
  static const int _settingsBranchIndex = 7;

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  void _goToBranch(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  void _toggleRailExtended() {
    setState(() => _railExtended = !_railExtended);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  /// Пункты меню (общие для drawer, rail и нижнего бара): навигационные ветки
  /// в едином порядке. «Профиль» и «Настройки» в список не входят — профиль
  /// открывается аватаром в шапке, настройки прижаты к низу меню.
  List<({int branchIndex, IconData icon, IconData selectedIcon, String label})>
  _menuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      (
        branchIndex: 0,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: l10n.navHome,
      ),
      (
        branchIndex: 1,
        icon: Icons.fitness_center_outlined,
        selectedIcon: Icons.fitness_center,
        label: l10n.navExercises,
      ),
      (
        branchIndex: _programsBranchIndex,
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        label: l10n.navPrograms,
      ),
      (
        branchIndex: _planBranchIndex,
        icon: Icons.event_note_outlined,
        selectedIcon: Icons.event_note,
        label: l10n.navPlan,
      ),
      (
        branchIndex: 4,
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        label: l10n.navProgress,
      ),
      (
        branchIndex: _historyBranchIndex,
        icon: Icons.history,
        selectedIcon: Icons.history,
        label: l10n.history,
      ),
    ];
  }

  /// Порядок веток в rail-списке (одинаков в обоих состояниях). Профиль в
  /// список не входит — его место в `leading`, пунктом меню под иконкой меню.
  static const List<int> _railBranchOrder = [
    0,
    1,
    2,
    3,
    4,
    _historyBranchIndex,
  ];

  List<NavigationRailDestination> _railDestinations(
    List<
      ({int branchIndex, IconData icon, IconData selectedIcon, String label})
    >
    items,
  ) {
    final byBranch = {for (final item in items) item.branchIndex: item};
    return [
      for (final branch in _railBranchOrder)
        NavigationRailDestination(
          icon: Icon(byBranch[branch]!.icon),
          selectedIcon: Icon(byBranch[branch]!.selectedIcon),
          label: Text(byBranch[branch]!.label),
        ),
    ];
  }

  /// Индекс выбранного пункта rail. Ветки без пункта (Профиль/Настройки) —
  /// `null`, чтобы соседний пункт не подсвечивался ложно.
  int? _railSelectedIndex() {
    final index = _railBranchOrder.indexOf(navigationShell.currentIndex);
    return index < 0 ? null : index;
  }

  void _onRailDestinationSelected(int i) {
    _goToBranch(_railBranchOrder[i]);
  }

  void _goToProfile() => _goToBranch(_profileBranchIndex);

  /// Профиль — пункт меню в шапке rail, ниже иконки меню (toggle).
  ///
  /// В расширенном состоянии иконка сворачивания — у правого края, профиль —
  /// слева с подписью; в свёрнутом (80dp) — подпись не помещается, остаётся
  /// аватар с tooltip. Высота блока профиля одинакова в обоих состояниях,
  /// чтобы пункты меню не смещались при переключении.
  Widget _buildRailProfile() {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selected = navigationShell.currentIndex == _profileBranchIndex;
    final avatar = ProfileAvatar(radius: 12, onTap: _goToProfile);
    if (_railExtended) {
      // Пункт меню: аватар — в колонке иконок (как у остальных пунктов),
      // подпись рядом. Левая колонка 80dp совпадает с колонкой иконок
      // направлений, поэтому профиль выровнен с остальными пунктами.
      return SizedBox(
        height: 48,
        child: InkWell(
          onTap: _goToProfile,
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: selected
                        ? BoxDecoration(
                            color: scheme.secondaryContainer,
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: avatar,
                  ),
                ),
              ),
              Text(
                l10n.navProfile,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    // Свёрнутое: аватар 24dp центрирован в колонке иконок, как и остальные
    // пункты (center, а не слева), чтобы выравниваться с ними по одной линии.
    return SizedBox(
      height: 48,
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  color: scheme.secondaryContainer,
                  shape: BoxShape.circle,
                )
              : null,
          child: Tooltip(message: l10n.navProfile, child: avatar),
        ),
      ),
    );
  }

  Widget _buildRailLeading() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: _railWidth,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка меню — сверху; свёрнутое: по центру колонки иконок
            // (одна линия с пунктами), расширенное: у правого края.
            SizedBox(
              height: 48,
              child: Align(
                alignment: _railExtended
                    ? Alignment.centerRight
                    : Alignment.center,
                child: IconButton(
                  icon: Icon(_railExtended ? Icons.menu_open : Icons.menu),
                  tooltip: _railExtended
                      ? l10n.navRailCollapse
                      : l10n.navRailExpand,
                  onPressed: _toggleRailExtended,
                ),
              ),
            ),
            _buildRailProfile(),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }

  void _goToSettings() => _goToBranch(_settingsBranchIndex);

  /// «Настройки», прижатые к низу rail за divider-ом (как в drawer).
  /// Ширина rail в текущем состоянии (M3-значения по умолчанию: 80 свернутый,
  /// 256 расширенный). NavigationRail не ограничивает leading/trailing по
  /// ширине (Column без bounds), поэтому любой дочерний виджет с flex-детьми или
  /// `double.infinity` рвётся; фиксируем ширину явно.
  double get _railWidth => _railExtended ? 256 : 80;

  Widget _buildRailTrailing() {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selected = navigationShell.currentIndex == _settingsBranchIndex;
    Widget footer;
    if (!_railExtended) {
      footer = IconButton(
        icon: Icon(
          selected ? Icons.settings : Icons.settings_outlined,
          color: selected ? scheme.primary : null,
        ),
        tooltip: l10n.settings,
        onPressed: _goToSettings,
      );
    } else {
      footer = ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: scheme.secondaryContainer,
        leading: Icon(selected ? Icons.settings : Icons.settings_outlined),
        title: Text(l10n.settings),
        onTap: _goToSettings,
      );
    }
    return SizedBox(
      width: _railWidth,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [const Divider(height: 1), footer],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useRail = AppBreakpoints.isExpanded(constraints.maxWidth);
        final items = _menuItems(context);

        final child = useRail
            ? Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _railSelectedIndex(),
                      onDestinationSelected: _onRailDestinationSelected,
                      leading: _buildRailLeading(),
                      trailing: _buildRailTrailing(),
                      trailingAtBottom: true,
                      extended: _railExtended,
                      destinations: _railDestinations(items),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(child: navigationShell),
                  ],
                ),
              )
            : Scaffold(
                key: _scaffoldKey,
                body: navigationShell,
                drawer: _buildDrawer(context, items),
                bottomNavigationBar: _buildBottomBar(context, items),
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
      ({int branchIndex, IconData icon, IconData selectedIcon, String label})
    >
    items,
  ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Шапка меню: профиль как пункт меню (аватар слева + подпись),
            // тап открывает Профиль.
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _goToBranch(_profileBranchIndex);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const ProfileAvatar(radius: 12),
                    const SizedBox(width: 16),
                    Text(
                      AppLocalizations.of(context).navProfile,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in items)
                    ListTile(
                      leading: Icon(item.icon),
                      selected:
                          item.branchIndex == navigationShell.currentIndex,
                      onTap: () {
                        Navigator.of(context).pop();
                        _goToBranch(item.branchIndex);
                      },
                      title: Text(item.label),
                    ),
                ],
              ),
            ),
            // «Настройки» прикреплены к низу меню, отделены divider-ом.
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              selected: navigationShell.currentIndex == _settingsBranchIndex,
              title: Text(AppLocalizations.of(context).settings),
              onTap: () {
                Navigator.of(context).pop();
                _goToBranch(_settingsBranchIndex);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Нижний бар из 4 вкладок.
  ///
  /// Когда активна ветка вне 4 вкладок (Прогресс/Профиль/История/Настройки,
  /// только через меню), `NavigationBar` требует valid `selectedIndex` в
  /// диапазоне, а «ничего не выбрано» в M3 не поддерживается. Чтобы бар не
  /// подсвечивал «План» на таких экранах, он оборачивается в
  /// `NavigationBarTheme` с прозрачным индикатором и единым цветом
  /// иконок/подписей — визуально ни одна вкладка не выбрана.
  Widget _buildBottomBar(
    BuildContext context,
    List<
      ({int branchIndex, IconData icon, IconData selectedIcon, String label})
    >
    items,
  ) {
    final int currentIndex = navigationShell.currentIndex;
    final bool isMenuOnly = currentIndex > 3;
    final bar = NavigationBar(
      selectedIndex: isMenuOnly ? 3 : currentIndex,
      onDestinationSelected: _goToBranch,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        for (final item in items.take(4))
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
      ],
    );
    if (!isMenuOnly) {
      return bar;
    }
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: colorScheme.onSurfaceVariant),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
      child: bar,
    );
  }
}
