/// Брейкпоинты адаптивного макета.
enum AppBreakpoint { compact, medium, expanded }

/// Классификация ширины экрана по Material 3 breakpoints:
/// compact < 600dp, medium 600–840dp, expanded >= 840dp.
abstract final class AppBreakpoints {
  static const double compactMaxWidth = 600;
  static const double mediumMaxWidth = 840;

  static AppBreakpoint of(double width) {
    if (width < compactMaxWidth) return AppBreakpoint.compact;
    if (width < mediumMaxWidth) return AppBreakpoint.medium;
    return AppBreakpoint.expanded;
  }

  static bool isCompact(double width) => of(width) == AppBreakpoint.compact;

  static bool isMedium(double width) => of(width) == AppBreakpoint.medium;

  static bool isExpanded(double width) => of(width) == AppBreakpoint.expanded;

  /// Минимальная ширина, на которой показываются подписи нижней навигации.
  static const double barLabelsMinWidth = 400;

  /// На узких экранах подписи нижней навигации скрываются, остаются иконки.
  static bool hidesBarLabels(double width) => width < barLabelsMinWidth;
}
