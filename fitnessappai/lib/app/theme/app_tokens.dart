// ignore_for_file: type=lint
import 'package:flutter/material.dart';

import 'package:fitnessappai/app/theme/status_colors.dart';

/// Дизайн-токены геометрии и прозрачности (DESIGN.md, §6, §11).
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

  /// Пилюля (stadium): значение заведомо больше любой высоты элемента,
  /// радиус фактически ограничен половиной высоты. Pill-кнопки и сегменты.
  static const double pill = 999;
}

/// Альфа-градации тинтов поверх container/series-цветов (DESIGN.md, §6).
///
/// Шкала закрытая: новые прозрачности не вводятся «на глаз» —
/// либо один из токенов, либо обоснование в DESIGN.md.
abstract final class AppTints {
  /// Едва заметный тинт: градиенты подложек, заливки областей графиков,
  /// фон бейджей.
  static const double faint = 0.15;

  /// Средний тинт: тонированные подсветки на container/series-цветах,
  /// масштабируется интенсивностью (`AppTints.medium * intensity`).
  /// Для неон-glow активных элементов использовать отдельную шкалу
  /// [AppGlow] (не этот токен).
  static const double medium = 0.35;

  /// Сильный тинт: акцентные плашки под иконками и чипы на container-цвете.
  static const double strong = 0.4;
}

/// Токены неонового свечения (glow) — редизайн 54 (DESIGN.md, §11).
///
/// Статичные свечения: без анимаций и пульсаций, не более одного glow
/// на виджет. Значения закрытой шкалы — новые свечения не задаются «на глаз».
abstract final class AppGlow {
  /// Радиус размытия свечения (blurRadius тени).
  static const double radius = 16;

  /// Расширение свечения за краем элемента (spreadRadius тени).
  static const double spread = 2;

  /// Базовая альфа свечения; интенсивность масштабируется
  /// (`AppGlow.alpha * intensity`).
  static const double alpha = 0.45;

  /// Альфа неоновой обводки (border) активного элемента.
  static const double borderAlpha = 0.8;
}

/// Токены градиентов — единая точка градиентов (DESIGN.md, §11).
///
/// Стопы подобраны так, чтобы белый текст держал AA (≥4.5:1) на всём
/// протяжении градиента (проверяется тестом `test/app/theme/app_tokens_test.dart`).
abstract final class AppGradients {
  /// Основной CTA-градиент: фиолет → синий (кнопки «Старт», «Сохранить»).
  static const LinearGradient primaryCta = LinearGradient(
    colors: [Color(0xFF6D46C4), Color(0xFF3F5FD9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Highlight-вариант: фиолет → розовый (статистика, акцентные числа).
  static const LinearGradient highlight = LinearGradient(
    colors: [Color(0xFF6D46C4), Color(0xFFC93B8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Hero-карточка главной (54.3): тёмно-синий → фиолет (стопы сэмплированы
  /// из образца `templates/IMG_20260920_204544.jpg`). Единственный
  /// «тёмный» градиент: им покрывается только роль «текущая/ближайшая
  /// тренировка», на нём — светлый текст (≥4.5:1, проверяется тестом).
  static const LinearGradient heroCard = LinearGradient(
    colors: [Color(0xFF14243D), Color(0xFF3A3468)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Градиент данных графиков (54.8): столбики срезов, линия метрики и
  /// прогрессии. Стопы — из проверенной палитры серий (`ChartSeriesColors`
  /// 0 и 3), контраст ≥4.5:1 к `surfaceContainerLow` в обеих темах
  /// проверяется тестом `app_tokens_test`.
  static LinearGradient chartLine(Brightness brightness) {
    final colors = brightness == Brightness.dark
        ? ChartSeriesColors.dark
        : ChartSeriesColors.light;
    return LinearGradient(
      colors: [colors[0], colors[3]],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Лёгкий «ролевой» градиент hero-подобных карточек в СВЕТЛОЙ теме
  /// (hero главной 54.3, stat-карточка прогресса 54.8): светлая тема без
  /// near-black поверхностей (DESIGN.md §11), фон — из поверхностных ролей.
  /// В тёмной теме используйте [heroCard].
  static LinearGradient roleSurface(ColorScheme scheme) => LinearGradient(
    colors: [
      scheme.surfaceContainerLow,
      scheme.primaryContainer.withValues(alpha: AppTints.faint),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
