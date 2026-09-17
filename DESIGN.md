# DESIGN.md — Fitness App (Flutter, Material 3, RU)

Единый источник дизайн-токенов и визуальных правил для фитнес-трекера (RU-локаль, кросс-платформа Android/iOS).

Статус: актуально. Дата ревизии: 2026-09-17.

---

## 1. Принципы (обязательны)

1. **Semantic-токены, никаких произвольных hex вне ролей.** Все цвета берутся из `ColorScheme` (роли Material 3) либо из перечисленных в этом документе выделенных констант. Прямые hex в коде разрешены **только** в трёх местах:
   - инициализация seed-цвета в `ColorScheme.fromSeed(seedColor: Color(0xFF7E57C2))`;
   - константы серий графиков `ChartSeriesColors` (см. раздел 5);
   - токены сетки графиков `chartGrid` (см. раздел 5).
2. **Красный — только для ошибок и деструктивных действий.** Роль `error`/`onError` не используется для статусов, не являющихся ошибками. «Пропущено» — нейтральный статус.
3. **Роли M3 не перекрашиваются.** `primary`, `tertiary`, `error` и поверхностные роли остаются ролями `ColorScheme`; типографика и layout не назначают им произвольные оттенки.
4. **Контраст проверяется парой (foreground + background), не цветом.** Любое изменение пары перепроверяется по WCAG 2.2 (см. раздел 7). Минимум:
   - текст: 4.5:1 (AA), 7:1 (AAA);
   - крупный текст и графика/UI-элементы (сетка, бордеры, линии, маркеры): 3:1 (AA, критерий 1.4.11).
5. **Все значения в этом документе вычислены**, не взяты «из головы»: M3-схема сгенерирована алгоритмом material-color-utilities (tonal spot, как `ColorScheme.fromSeed`) из `#7E57C2`; contrasts рассчитаны по формуле относительной светимости WCAG.

---

## 2. Базовая M3-палитра (справочная)

Источник: `ColorScheme.fromSeed(seedColor: Color(0xFF7E57C2))`, **light + dark**, tonal spot. Значения ниже — реальный результат генерации на текущей версии схемы; они справочные (в коде брать из `colorScheme`, не литералами).

### Light

| Токен (роль) | Hex | OKLCH (L C H) |
|---|---|---|
| `primary` | `#69548D` | 0.491 0.092 300.0 |
| `onPrimary` | `#FFFFFF` | 1.000 0.000 — |
| `primaryContainer` | `#EBDCFF` | 0.917 0.050 304.8 |
| `onPrimaryContainer` | `#503C74` | 0.405 0.093 298.6 |
| `secondary` | `#635B70` | 0.486 0.035 302.5 |
| `secondaryContainer` | `#EADEF7` | 0.918 0.036 307.2 |
| `tertiary` | `#7F525D` | 0.492 0.062 3.7 |
| `onTertiary` | `#FFFFFF` | 1.000 0.000 — |
| `tertiaryContainer` | `#FFD9E0` | 0.919 0.043 5.5 |
| `onTertiaryContainer` | `#643B45` | 0.405 0.059 4.3 |
| `error` | `#BA1A1A` | 0.506 0.193 27.7 |
| `onError` | `#FFFFFF` | 1.000 0.000 — |
| `surface` | `#FEF7FF` | 0.984 0.013 321.9 |
| `onSurface` | `#1D1B20` | 0.227 0.010 303.7 |
| `onSurfaceVariant` | `#49454E` | 0.398 0.016 305.7 |
| `outline` | `#7A757F` | 0.570 0.016 308.1 |
| `outlineVariant` | `#CBC4CF` | 0.829 0.017 313.6 |
| `surfaceContainerLowest` | `#FFFFFF` | 1.000 0.000 — |
| `surfaceContainerLow` | `#F8F1FA` | 0.966 0.014 318.7 |
| `surfaceContainer` | `#F2ECF4` | 0.950 0.012 317.7 |
| `surfaceContainerHigh` | `#EDE6EE` | 0.933 0.013 321.9 |
| `surfaceContainerHighest` | `#E7E0E8` | 0.915 0.013 321.9 |

### Dark

| Токен (роль) | Hex | OKLCH (L C H) |
|---|---|---|
| `primary` | `#D4BBFC` | 0.835 0.093 302.0 |
| `onPrimary` | `#39255C` | 0.319 0.095 297.5 |
| `primaryContainer` | `#503C74` | 0.405 0.093 298.6 |
| `onPrimaryContainer` | `#EBDCFF` | 0.917 0.050 304.8 |
| `secondary` | `#CDC2DB` | 0.831 0.036 305.4 |
| `secondaryContainer` | `#4B4358` | 0.399 0.036 302.2 |
| `tertiary` | `#F1B7C4` | 0.836 0.069 3.8 |
| `onTertiary` | `#4A252F` | 0.318 0.057 3.6 |
| `tertiaryContainer` | `#643B45` | 0.405 0.059 4.3 |
| `error` | `#FFB4AB` | 0.838 0.089 26.8 |
| `onError` | `#690005` | 0.328 0.134 27.3 |
| `surface` | `#151218` | 0.189 0.013 307.7 |
| `onSurface` | `#E7E0E8` | 0.915 0.013 321.9 |
| `onSurfaceVariant` | `#CBC4CF` | 0.829 0.017 313.6 |
| `outline` | `#948E99` | 0.655 0.017 310.0 |
| `outlineVariant` | `#49454E` | 0.398 0.016 305.7 |
| `surfaceContainerLowest` | `#0F0D13` | 0.164 0.013 300.2 |
| `surfaceContainerLow` | `#1D1B20` | 0.227 0.010 303.7 |
| `surfaceContainer` | `#211F24` | 0.244 0.010 303.8 |
| `surfaceContainerHigh` | `#2C292F` | 0.287 0.012 308.0 |
| `surfaceContainerHighest` | `#37343A` | 0.330 0.011 308.1 |

---

## 3. Где какой цвет (карта экранов)

| Поверхность / элемент | Роль | Light | Dark |
|---|---|---|---|
| Scaffold (`scaffoldBackgroundColor`) | `surface` | `#FEF7FF` | `#151218` |
| Card | `surfaceContainerLow` | `#F8F1FA` | `#1D1B20` |
| NavigationBar / NavigationRail | `surfaceContainer` | `#F2ECF4` | `#211F24` |
| Индикатор выбранного пункта навигации | `primaryContainer` (индикатор) | `#EBDCFF` | `#503C74` |
| SearchBar | `surfaceContainerHigh` | `#EDE6EE` | `#2C292F` |
| Dialog | `surfaceContainerHigh` | `#EDE6EE` | `#2C292F` |
| Заголовки / основной текст | `onSurface` | `#1D1B20` | `#E7E0E8` |
| Вторичный текст, плейсхолдеры, подписи | `onSurfaceVariant` | `#49454E` | `#CBC4CF` |
| Иконки вторичного уровня, несфокусированные элементы | `onSurfaceVariant` | `#49454E` | `#CBC4CF` |
| Границы полей, «спокойные» бордеры | `outline` | `#7A757F` | `#948E99` |
| Разделители без притязания на акцент | `outlineVariant` | `#CBC4CF` | `#49454E` |

Ограничение: не используйте `outlineVariant` там, где элемент должен быть различим по контрасту ≥3:1 (сетка графиков — отдельный токен, раздел 5).

**Профиль (замеры тела: вес / ИМТ / жир):** текстовые значения/заголовки — `onSurface`; цифровые метрики на карточках — `onSurface`; подписи единиц — `onSurfaceVariant`. Два значения одного параметра (например, старый и новый вес) — старое значение `onSurfaceVariant` с зачёркиванием, новое — `primary`. Данные — числа, а не цвет: поэтому у положительной/отрицательной динамики нет цветовой окраски «зелёный/красный», красный зарезервирован за `error` (например, ввод невозможного значения ИМТ).

**Диаграмма мышц:** группы мышц — схемы-тоновая заливка `primaryContainer`/`onPrimaryContainer`; неактивные зоны — `surfaceContainerHighest`; текущая выделенная мышца — `primary`/`onPrimary`. Никаких «тепловой» раскраски.

**Настройки:** переключатели/чекбоксы — `primary`; фон — `surface`; разделители — `outlineVariant`; опасные действия («Сбросить прогресс») — `error`.

---

## 4. Цвета статусов (Status colors)

### Правило

- `pending` — нейтральная ожидание (tonal chip);
- `performed` — главное действие, заполненный primary-чип;
- `rescheduled` — планируемое изменение, tertiary-чип;
- `skipped` и `pastSkipped` — **«пропущено» — нейтральная отмена**, а не ошибка. Используется outlined-чип (контейнер + бордер + текст), текст/иконка — `onSurfaceVariant`. `pastSkipped` является алиасом `skipped` (те же токены) — так исторический и текущий пропуск выглядят одинаково, а «красный» остаётся только у `error`.
- `error` — только ошибки/деструктивное действие (роль `error` не меняется).

Отличимость статусов достигается не только цветом, но и формой/стилем: у `skipped` — outlined-чип (без заливки акцента), у `pending` — тонированный fill, у `performed`/`rescheduled` — цветные fill. Иконки усиливают: pending — часы/ожидание, performed — галочка, rescheduled — стрелка/обновление, skipped — «прочерк» (dash) или зачёркнутый элемент.

### Токены (роли — всё из `ColorScheme`, кроме выделенного блока skipped)

| Статус | Light: контейнер / содержимое | Контраст | Dark: контейнер / содержимое | Контраст | Метка WCAG 2.2 |
|---|---|---|---|---|---|
| `statusPending` | `surfaceContainerHighest` / `onSurfaceVariant` (`#E7E0E8` / `#49454E`) | 7.23:1 | `#37343A` / `#CBC4CF` | 7.19:1 | AA + AAA (текст) |
| `statusPerformed` | `primary` / `onPrimary` (`#69548D` / `#FFFFFF`) | 6.45:1 | `#D4BBFC` / `#39255C` | 7.73:1 | AA (light), AA+AAA (dark) |
| `statusRescheduled` | `tertiary` / `onTertiary` (`#7F525D` / `#FFFFFF`) | 6.43:1 | `#F1B7C4` / `#4A252F` | 7.71:1 | AA (light), AA+AAA (dark) |
| `statusSkipped` (text) | `surfaceContainerLow` / `onSurfaceVariant` (`#F8F1FA` / `#49454E`) | 8.44:1 | `#1D1B20` / `#CBC4CF` | 10.03:1 | AA + AAA (текст) |
| `statusSkipped` (border) | `surfaceContainerLow` / `outline` (`#F8F1FA` / `#7A757F`) | 4.05:1 | `#1D1B20` / `#948E99` | 5.36:1 | AA — графика/UI (≥3:1, критерий 1.4.11); **не** использовать как текст |
| `statusError` | `error` / `onError` (`#BA1A1A` / `#FFFFFF`) | 6.46:1 | `#FFB4AB` / `#690005` | 7.72:1 | AA (light), AA+AAA (dark) |

Граница outlined-чипа (4.05:1 в light) — допустимый для UI-графики контраст; текст и иконка внутри чипа всегда `onSurfaceVariant`, поэтому текстовый критерий 4.5:1 выполняется.

### Бейджи (визуальные спецификации)

- `pending`: Filled/tonal chip — bg `surfaceContainerHighest`, content `onSurfaceVariant`, без бордера.
- `performed`: Filled chip — bg `primary`, content `onPrimary`.
- `rescheduled`: Filled chip — bg `tertiary`, content `onTertiary`.
- `skipped` / `pastSkipped`: Outlined chip — bg `surfaceContainerLow`, border `outline` (1–1.5 dp), content `onSurfaceVariant`, иконка прочерка. Заливка акцента отсутствует.
- `error` (если некий статус — ошибка, например «сбой записи»): Filled chip — bg `error`, content `onError`.

---

## 5. Цвета графиков (Chart colors)

### Правила выбора палитры

1. **categorical** — по умолчанию для нескольких тренировок/упражнений/мышц на одном графике (`LineChart` в экране Прогресс). Используется `ChartSeriesColors` (6 серий) в фиксированном порядке индексов 0→5, одинаковом для light/dark, чтобы соответствие серий не путалось при смене темы.
2. **sequential** — упорядоченная интенсивность одной метрики (например, суммарный объём/нагрузка по дням недели). Берётся **один** базовый цвет (обычно `primary` для стержней, `chartSeries0` для линий) и строится непрозрачная градация смешиванием с фоном `surface` **в OKLCH** (шаг по L, C не трогаем). Каждая градация должна оставаться ≥3:1 на `surface` в обоих brightness; для подписей градаций — ≥4.5:1 (использовать текстовый токен `onSurfaceVariant`). Не разводить alpha произвольно — только по явно просчитанной шкале.
3. **semantic** — смысловая окраска (ванна/норма/высокий, рост/спад). Красный **запрещён** (резерв `error`). Для «рост/спад» используем пару: рост — `primary`, спад — нейтральный `onSurfaceVariant` (не красный; семантика передаётся стрелками/значениями). Для зон-нормы на линейном графике — зона с заливкой `primaryContainer` (заливка может быть полупрозрачной к фону `surface`, но базовый контраст зоны — от `primaryContainer`).
4. Один график — **одна из трёх** палитр. Смешивать categorical и semantic на одном графике нельзя.
5. Больше 6 линий на одном графике запрещено: переполняется различаемость; вместо этого фильтр/выбор по индексам серий (максимум 6 активных).

### Сетка и оси

| Токен | Роль | Light | Dark | Контраст к `surface` | Метка |
|---|---|---|---|---|---|
| `chartGrid` | сетка графика (линии) | `#878787` | `#696969` | 3.41:1 / 3.38:1 | AA — графика/UI (≥3:1) |
| `chartAxisLabel` | подписи значений и единиц на осях | `onSurfaceVariant` (`#49454E`) | `onSurfaceVariant` (`#CBC4CF`) | 8.89:1 / 10.90:1 | AA + AAA (текст) |

Правила сетки:
- Токен меняет заменяет текущую сетку `outlineVariant` с alpha 0.3 (контраст <3:1) — она была нарушением.
- Сетка рисуется **сплошным** нейтральным токеном без alpha (alpha поверх составных поверхностей снова ломает контраст). «Спокойствие» достигается толщиной 0.5–1 px, без dash и без акцентной хроматики; первичные данные всегда рисоваться поверх и толще (линии ≥2 px), поэтому grid визуально тише, чем данные.
- Подписи осей и единицы: `chartAxisLabel` (палитра осей не меняется).

### Серии (категориальная палитра)

Инварианты для обеих тем: каждый цвет ≥4.5:1 к `surface` (запас над требованием 3:1 для графики), минимальная попарная разница ΔE2000 ≥ 15 (светлая) / ≥ 22 (тёмная), и у каждой близкой по цвету пары есть разница по светлоте OKLCH L.

#### Light (фон `surface` `#FEF7FF`)

| Токен | Hex | OKLCH (L C H) | Контраст к `surface` | Роль |
|---|---|---|---|---|
| `chartSeries0` | `#0051A0` | 0.441 0.145 254.9 | 7.44:1 | indigo |
| `chartSeries1` | `#00432E` | 0.339 0.072 164.7 | 10.84:1 | teal |
| `chartSeries2` | `#9A5500` | 0.520 0.121 60.4 | 5.43:1 | amber |
| `chartSeries3` | `#710085` | 0.400 0.192 320.0 | 9.78:1 | magenta |
| `chartSeries4` | `#566600` | 0.480 0.114 119.8 | 6.06:1 | green |
| `chartSeries5` | `#004C56` | 0.382 0.066 209.8 | 9.21:1 | azure |

#### Dark (фон `surface` `#151218`)

| Токен | Hex | OKLCH (L C H) | Контраст к `surface` | Роль |
|---|---|---|---|---|
| `chartSeries0` | `#67AAFF` | 0.730 0.142 255.1 | 7.75:1 | indigo |
| `chartSeries1` | `#00AC7D` | 0.660 0.138 165.2 | 6.36:1 | teal |
| `chartSeries2` | `#FFC392` | 0.860 0.094 60.3 | 11.91:1 | amber |
| `chartSeries3` | `#E365FF` | 0.720 0.239 320.0 | 6.69:1 | magenta |
| `chartSeries4` | `#B5D500` | 0.820 0.195 120.0 | 11.03:1 | green |
| `chartSeries5` | `#00D2EB` | 0.791 0.137 209.9 | 10.09:1 | azure |

Хранение: константы `ChartSeriesColors` (см. раздел 8) — значения записаны литералами, потому что это единственное место, где цвет не является ролью `ColorScheme`. Один и тот же индекс серии в light и dark — одно и то же упражнение/мышца.

Столбики (BarChart «тренировки по периодам»): одна серия — `primary` (как в коде, без изменений): light `#69548D` / `#D4BBFC` dark, контраст к `surface` 6.14:1 / 10.88:1.

---

## 6. Элевация и низ-уровневые правила

- `scaffoldBackgroundColor = surface`; карточки `surfaceContainerLow`; навигация `surfaceContainer`; строка поиска и диалоги `surfaceContainerHigh`. Это уровни элевации, зафиксированные в коде; не менять без ревью дизайн-системы.
- **Не более трёх уровней поверхности в одном viewport** (например, фон + карточка + всплывающий элемент). Каждый уровень добавляет шаг тона, а не произвольную заливку.
- Уровень выше `surfaceContainerHigh` (модалки поверх диалога) — только `surfaceContainerHighest`, в крайнем случае с фокусом и scrim на фоне. Не придумывать новые контейнерные роли.
- Текстовые пары `onSurface`/`onSurfaceVariant` на любом контейнерном уровне проверены и проходят AA/AAA (все значения ≥7.19:1); поэтому валидные элементы каждой поверхности используют эти две пары.
- Тени: тональная элевация M3; для карточек — минимальная бокс-тень или её замена тональной заливкой контейнера. Не накладывать глубокие тени на карточки, иначе элевация перегружается.
- Разделители между карточками — `outlineVariant` с альфа к фону только при декоративном использовании (не критичные информационные элементы); разделители, несущие структуру (списки), — `outline` 1dp при необходимости.

---

## 7. Верификация контраста (процедура)

При любом изменении цвета:

1. Регенерируйте M3-схему из seed через `ColorScheme.fromSeed` — значения ролей должны остаться ровно теми, что в разделе 2 (иначе менялся seed или схема, это отдельное решение).
2. Для каждой изменённой пары (fg+bg) вычислите WCAG-контраст: текст ≥4.5:1, графика/UI ≥3:1. Проверяйте в **обоих** brightness.
3. Для серий графиков: проверьте ≥4.5:1 к `surface` и попарный ΔE2000 ≥15 к соседним сериям; при добавлении серии не сдвигайте hue-порядок существующих.
4. Критерии оценки: AA/AAA для текста; AA (1.4.11) для графики; fail — если ниже порога.

---

## 8. Пример использования в Dart

Не ломает существующий `ThemeData`: `ColorScheme.fromSeed` остаётся как есть; статусы и графики потребляют `ColorScheme` через extension и константы.

```dart
// status_colors.dart
import 'package:flutter/material.dart';

/// Дополнительные семантические роли поверх M3 ColorScheme.
/// Читают существующие роли — никаких новых hex.
extension StatusColorsX on ColorScheme {
  // «Пропущено» — нейтральная отмена (НЕ error!).
  // Outlined chip: bg statusSkippedContainer, border statusSkippedOutline,
  // текст/иконка: statusSkippedOnContainer.
  Color get statusSkippedContainer => surfaceContainerLow;
  Color get statusSkippedOutline  => outline;
  Color get statusSkippedOnContainer => onSurfaceVariant;
  Color get statusPendingContainer => surfaceContainerHighest;
  Color get statusPendingOnContainer => onSurfaceVariant;
  Color get statusPerformedContainer => primary;
  Color get statusPerformedOnContainer => onPrimary;
  Color get statusRescheduledContainer => tertiary;
  Color get statusRescheduledOnContainer => onTertiary;
  Color get statusErrorContainer => error;
  Color get statusErrorOnContainer => onError;

  // Сетка графиков: >= 3:1 к surface, обе темы проверены.
  Color get chartGrid =>
      brightness == Brightness.light
          ? const Color(0xFF878787)
          : const Color(0xFF696969);

  // Подписи осей графиков.
  Color get chartAxisLabel => onSurfaceVariant;
}

/// Категориальная палитра серий графиков (до 6 линий).
/// Light и dark — разные значения: ни один цвет не может быть >=4.5:1
/// одновременно к #FEF7FF и к #151218.
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

// Использование:
//   final cs = Theme.of(context).colorScheme;
//   SkippedBadge(... bg: cs.statusSkippedContainer,
//                    border: cs.statusSkippedOutline,
//                    labelColor: cs.statusSkippedOnContainer);
//   // fl_chart (линии)
//   LineChartBarData(color: ChartSeriesColors.of(brightness, seriesIndex));
//   // fl_chart (сетка) — заменить outlineVariant/alpha на:
//   FlGridData(getDrawingHorizontalLine: (_) => FlLine(color: cs.chartGrid));
```

---

## 9. Типографика

Базовые значения — M3-дефолты `TextTheme` (не задаются вручную). Роль → size / weight / line-height:

| Стиль | Роль в коде | size / h | weight |
|---|---|---|---|
| Display Large | `displayLarge` | 57 / 64 | regular (400) |
| Display Medium | `displayMedium` | 45 / 52 | regular |
| Headline Large | `headlineLarge` | 32 / 40 | regular |
| Headline Small | `headlineSmall` | 24 / 32 | regular |
| Title Large | `titleLarge` | 22 / 28 | regular |
| Title Medium | `titleMedium` | 16 / 24 | medium (500) |
| Title Small | `titleSmall` | 14 / 20 | medium |
| Body Large | `bodyLarge` | 16 / 24 | regular |
| Body Medium | `bodyMedium` | 14 / 20 | regular |
| Body Small | `bodySmall` | 12 / 16 | regular |
| Label Large | `labelLarge` | 14 / 20 | medium |
| Label Small | `labelSmall` | 11 / 16 | medium |

Правила:
- Системный шрифт платформы (Roboto на Android, System/SF на iOS). Не жёстко фиксировать fontFamily; RU-кириллица покрывается системным шрифтом.
- Текст — всегда роли `onSurface` / `onSurfaceVariant` (см. раздел 3). Не уменьшать контраст при hover/disabled (отдельное правило в разделе 7).
- Для RU не применять `textTransform: uppercase` без явной причины в дизайне — русская типографика в ALL CAPS менее читаема в подписях/бейджах.
- Минимальный размер текста в данных графиков/инфографики — 11 dp (`labelSmall`); размеры ниже — по таблице M3, не ниже 11.

---

## 10. Адаптив (Адаптивность)

- **Платформа:** Android/iOS — единая M3-схема из seed; систему шрифтов оставить системной. Кастомные компаненты (бейджи статусов, графики) — одинаковые в обеих ОС.
- **Touch targets:** M3 минимум 48×48 dp (Android), Apple HIG 44×44 pt (iOS). Кнопки копирования/иконки-чипы статусов ≥44 dp; отдельные интерактивные маркеры графика — ≥44.
- **Навигация:** `NavigationRail` на широких экранах (планшет/раскладка ≥840 dp), `NavigationBar` — на телефонах; точка переключения 840 dp (M3-брейкпоинт). Rail — ширина 80 dp, расширенная 256 dp.
- **Локаль/локализация:** все строки — из l10n (ARB), не зашивать текст в виджеты; числовой формат веса/повторов — в зависимости от локали (ru-RU). Ширина подписей осей графиков должна выдерживать «12 345 кг» в локальной раскладке.
- **Не сжимать desktop layout:** на узких экранах (≤360 dp) линейный график перестраивается — подписи осей остаются, сетка та же; карточки программ переходят в 1 колонку.

---

## 11. Чейнджлог

- 2026-09-17 — создан документ. Добавлены: статусные токены `statusSkipped*` (нейтральная отмена вместо `error`), токен сетки `chartGrid` (≥3:1), категориальная палитра `ChartSeriesColors` (6 серий, light/dark, WCAG ≥4.5:1, ΔE≥15), карта поверхностей, верификация контраста.