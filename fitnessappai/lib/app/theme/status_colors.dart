import 'package:flutter/material.dart';

/// Дополнительные семантические роли поверх M3 ColorScheme.
///
/// Читают существующие роли — никаких новых hex (кроме токенов графиков,
/// которые не являются ролями `ColorScheme`). Источник: `DESIGN.md`.
extension StatusColorsX on ColorScheme {
  // «Пропущено» — нейтральная отмена (НЕ error!).
  // Outlined chip: bg statusSkippedContainer, border statusSkippedOutline,
  // текст/иконка: statusSkippedOnContainer.
  Color get statusSkippedContainer => surfaceContainerLow;
  Color get statusSkippedOutline => outline;
  Color get statusSkippedOnContainer => onSurfaceVariant;
  Color get statusPendingContainer => surfaceContainerHighest;
  Color get statusPendingOnContainer => onSurfaceVariant;
  Color get statusPerformedContainer => primary;
  Color get statusPerformedOnContainer => onPrimary;
  Color get statusRescheduledContainer => tertiary;
  Color get statusRescheduledOnContainer => onTertiary;
  Color get statusErrorContainer => error;
  Color get statusErrorOnContainer => onError;

  // Сетка графиков: >= 3:1 к surface, обе темы проверены (DESIGN.md).
  Color get chartGrid => brightness == Brightness.light
      ? const Color(0xFF878787)
      : const Color(0xFF696969);

  // Подписи осей графиков.
  Color get chartAxisLabel => onSurfaceVariant;
}

/// Категориальная палитра серий графиков (до 6 линий).
///
/// Light и dark — разные значения: ни один цвет не может быть >=4.5:1
/// одновременно к `#FEF7FF` и к `#151218` (DESIGN.md, раздел 5).
abstract final class ChartSeriesColors {
  static const List<Color> light = [
    Color(0xFF0051A0), // indigo
    Color(0xFF00432E), // teal
    Color(0xFF9A5500), // amber
    Color(0xFF710085), // magenta
    Color(0xFF566600), // green
    Color(0xFF004C56), // azure
  ];
  static const List<Color> dark = [
    Color(0xFF67AAFF),
    Color(0xFF00AC7D),
    Color(0xFFFFC392),
    Color(0xFFE365FF),
    Color(0xFFB5D500),
    Color(0xFF00D2EB),
  ];
  static const int count = 6;

  static Color of(Brightness brightness, int index) {
    final i = index % count;
    return brightness == Brightness.dark ? dark[i] : light[i];
  }
}
