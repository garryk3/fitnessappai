/// Дизайн-токены геометрии и прозрачности (DESIGN.md, §6).
///
/// Единая шкала скруглений и альфа-тинтов: экраны не задают
/// `BorderRadius.circular`/`withValues(alpha:)` произвольными числами —
/// только именованные значения отсюда.
abstract final class AppRadii {
  /// Мелкие элементы: бары графиков, микро-маркеры, тонкие линейки.
  static const double xs = 4;

  /// Чипы, плашки, малые плитки и превью.
  static const double sm = 8;

  /// Контейнеры-блоки, иконочные плитки, карточки-строки.
  static const double md = 12;

  /// Крупные карточки и кнопки.
  static const double lg = 16;

  /// Крупные карточки UI-кита ([AppCard]).
  static const double xl = 20;

  /// Формы M3 (FAB, крупные контейнеры темы).
  static const double xxl = 24;
}

/// Альфа-градации тинтов поверх container/series-цветов (DESIGN.md, §6).
///
/// Шкала закрытая: новые прозрачности не вводятся «на глаз» —
/// либо один из токенов, либо обоснование в DESIGN.md.
abstract final class AppTints {
  /// Едва заметный тинт: градиенты подложек, заливки областей графиков,
  /// фон бейджей.
  static const double faint = 0.15;

  /// Средний тинт: подсветка/глоу, масштабируется интенсивностью
  /// (`AppTints.medium * intensity`).
  static const double medium = 0.35;

  /// Сильный тинт: акцентные плашки под иконками и чипы на container-цвете.
  static const double strong = 0.4;
}
