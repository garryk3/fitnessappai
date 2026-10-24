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

> **Редизайн 54 (§11):** поверхности `surface`/`surfaceContainer*` тёмной темы переопределены на near-black значения (фон глубже M3 `#151218`). Таблица ниже — справочная генерация `fromSeed`; фактические поверхности — в §11 и в карте экранов (§3). Акценты (`primary`, `tertiary`, `error` и т.д.) остаются из seed.

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
| Scaffold (`scaffoldBackgroundColor`) | `surface` | `#FEF7FF` | `#101018` (54) |
| Card | `surfaceContainerLow` | `#F8F1FA` | `#17171F` (54) |
| NavigationBar / NavigationRail | `surfaceContainer` | `#F2ECF4` | `#1C1C25` (54) |
| Индикатор выбранного пункта навигации | `primaryContainer` (индикатор) | `#EBDCFF` | `#503C74` |
| SearchBar | `surfaceContainerHigh` | `#EDE6EE` | `#232330` (54) |
| Dialog | `surfaceContainerHigh` | `#EDE6EE` | `#232330` (54) |
| Заголовки / основной текст | `onSurface` | `#1D1B20` | `#E7E0E8` |
| Вторичный текст, плейсхолдеры, подписи | `onSurfaceVariant` | `#49454E` | `#CBC4CF` |
| Иконки вторичного уровня, несфокусированные элементы | `onSurfaceVariant` | `#49454E` | `#CBC4CF` |
| Границы полей, «спокойные» бордеры | `outline` | `#7A757F` | `#948E99` |
| Разделители без притязания на акцент | `outlineVariant` | `#CBC4CF` | `#49454E` |

Значения Dark с пометкой **(54)** — near-black поверхности редизайна (см. §11); генерация `fromSeed` для них переопределена в `AppTheme.dark()`. Остальные Dark-роли — из seed без изменений.

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
| `statusPending` | `surfaceContainerHighest` / `onSurfaceVariant` (`#E7E0E8` / `#49454E`) | 7.23:1 | `#2D2D3C` / `#CBC4CF` (54) | 7.95:1 | AA + AAA (текст) |
| `statusPerformed` | `primary` / `onPrimary` (`#69548D` / `#FFFFFF`) | 6.45:1 | `#D4BBFC` / `#39255C` | 7.73:1 | AA (light), AA+AAA (dark) |
| `statusRescheduled` | `tertiary` / `onTertiary` (`#7F525D` / `#FFFFFF`) | 6.43:1 | `#F1B7C4` / `#4A252F` | 7.71:1 | AA (light), AA+AAA (dark) |
| `statusSkipped` (text) | `surfaceContainerLow` / `onSurfaceVariant` (`#F8F1FA` / `#49454E`) | 8.44:1 | `#17171F` / `#CBC4CF` (54) | 10.47:1 | AA + AAA (текст) |
| `statusSkipped` (border) | `surfaceContainerLow` / `outline` (`#F8F1FA` / `#7A757F`) | 4.05:1 | `#17171F` / `#948E99` (54) | 5.59:1 | AA — графика/UI (≥3:1, критерий 1.4.11); **не** использовать как текст |
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

#### Dark (фон `surface` `#101018`, см. §11)

| Токен | Hex | OKLCH (L C H) | Контраст к `surface` | Роль |
|---|---|---|---|---|
| `chartSeries0` | `#67AAFF` | 0.730 0.142 255.1 | 7.75:1 | indigo |
| `chartSeries1` | `#00AC7D` | 0.660 0.138 165.2 | 6.36:1 | teal |
| `chartSeries2` | `#FFC392` | 0.860 0.094 60.3 | 11.91:1 | amber |
| `chartSeries3` | `#E365FF` | 0.720 0.239 320.0 | 6.69:1 | magenta |
| `chartSeries4` | `#B5D500` | 0.820 0.195 120.0 | 11.03:1 | green |
| `chartSeries5` | `#00D2EB` | 0.791 0.137 209.9 | 10.09:1 | azure |

Хранение: константы `ChartSeriesColors` (см. раздел 8) — значения записаны литералами, потому что это единственное место, где цвет не является ролью `ColorScheme`. Один и тот же индекс серии в light и dark — одно и то же упражнение/мышца.

Столбики (BarChart «Тренировки по срезам», 54.8) и линии данных (метрика, прогрессия) — **единый токен градиента данных `AppGradients.chartLine(brightness)`**: стопы — из категориальной палитры (серия 0 → серия 3), контраст ≥4.5:1 к карточке `surfaceContainerLow` в обеих темах (автотест `app_tokens_test`, `chartLine: данные графиков держат AA к карточке`). Подсветка двух последних непустых срезов — светлая **подложка-колонка** `surfaceContainerHigh` за столбиком: `BarChartData.rangeAnnotations` (`VerticalRangeAnnotation`) — рисуется `AxisChartPainter.paint()` **ДО** баров; **`extraLinesData.verticalLines` в BarChart НЕ рисуются** (fl_chart 1.2.0, issue #1149) — подложка только через аннотации, границы колонки вычисляются той же формулой `spaceEvenly`, что `calculateGroupsX` (выравнивание по центрам групп; хелпер `_evenlyGroupCenters`). Подсветка читается в обеих темах — перекраска градиента не используется (design-review 54.8). Заливка под линией — тот же градиент с `AppTints.faint`; **`isCurved` остаётся `false`** — сглаженная кривая проходит выше/ниже реальных точек и дезинформирует (визуал образца достигается градиентом/заливкой, геометрия честная; решение владельца 2026-10-19).

---

## 6. Элевация и низ-уровневые правила

- `scaffoldBackgroundColor = surface`; карточки `surfaceContainerLow`; навигация `surfaceContainer`; строка поиска и диалоги `surfaceContainerHigh`. Это уровни элевации, зафиксированные в коде; не менять без ревью дизайн-системы.
- **Не более трёх уровней поверхности в одном viewport** (например, фон + карточка + всплывающий элемент). Каждый уровень добавляет шаг тона, а не произвольную заливку.
- Уровень выше `surfaceContainerHigh` (модалки поверх диалога) — только `surfaceContainerHighest`, в крайнем случае с фокусом и scrim на фоне. Не придумывать новые контейнерные роли.
- Текстовые пары `onSurface`/`onSurfaceVariant` на любом контейнерном уровне проверены и проходят AA/AAA; поэтому валидные элементы каждой поверхности используют эти две пары (тёмная тема редизайна — значения выше M3-базы, см. §11; автотест `test/app/theme/app_theme_test.dart`).
- Тени: тональная элевация M3; для карточек — минимальная бокс-тень или её замена тональной заливкой контейнера. Не накладывать глубокие тени на карточки, иначе элевация перегружается.
- Разделители между карточками — `outlineVariant` с альфа к фону только при декоративном использовании (не критичные информационные элементы); разделители, несущие структуру (списки), — `outline` 1dp при необходимости.

### Токены скруглений и тинтов (`lib/app/theme/app_tokens.dart`)

Шкала закрытая: экраны берут значения только из токенов, произвольные числа в `BorderRadius.circular(...)`/`withValues(alpha:)` — нарушение.

**Скругления (`AppRadii`):**

| Токен | Значение | Роль |
|---|---|---|
| `AppRadii.xs` | 4 | мелочь: бары графиков, микро-маркеры, тонкие линейки |
| `AppRadii.sm` | 8 | чипы, плашки, малые плитки и превью |
| `AppRadii.md` | 12 | контейнеры-блоки, иконочные плитки, строки-карточки |
| `AppRadii.lg` | 16 | крупные карточки и кнопки |
| `AppRadii.xl` | 20 | карточки UI-кита (`AppCard`) |
| `AppRadii.xxl` | 24 | формы M3 (FAB, крупные контейнеры темы) |
| `AppRadii.pill` | 999 | пилюля (stadium): pill-кнопки и сегменты; радиус фактически ограничен половиной высоты |

**Тинты (`AppTints`) — альфа поверх container/series-цветов:**

| Токен | Значение | Роль |
|---|---|---|
| `AppTints.faint` | 0.15 | градиенты подложек, заливки областей графиков, фон бейджей |
| `AppTints.medium` | 0.35 | тонированные подсветки на container/series-цветах, масштабируется интенсивностью (`medium * intensity`); для неон-glow активных элементов — отдельная шкала `AppGlow` (§11) |
| `AppTints.strong` | 0.4 | акцентные плашки под иконками, чипы на container-цвете |

Значения вне шкалы (тени M3, scrim, внутренние константы `lib/uikit/`) — прерогатива слоя темы/UI-кита; новые экраны шкалу не расширяют без правки этого раздела.

---

## 7. Верификация контраста (процедура)

При любом изменении цвета:

1. Регенерируйте M3-схему из seed через `ColorScheme.fromSeed` — значения ролей должны остаться ровно теми, что в разделе 2, **кроме near-black поверхностей тёмной темы редизайна (§11)** — для них эталон §11/§3 (иначе менялся seed или схема, это отдельное решение).
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
/// одновременно к #FEF7FF и к #101018 (dark-фон редизайна, §11).
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

## 11. Редизайн 54 (токены и компоненты)

Фундамент редизайна по образцам владельца (`templates/`). Порядок задач: сначала фундамент (эта секция), затем экраны. IA не меняется — только визуальный слой.

### Тёмная тема: near-black поверхности

Тёмная тема остаётся «визитной карточкой» приложения. Поверхности переопределяются поверх генерации `ColorScheme.fromSeed` в `AppTheme.dark()` (`copyWith`); акценты (`primary`, `tertiary`, `error` и т.д.) остаются seed-значениями.

| Роль | Hex | Роль в иерархии |
|---|---|---|
| `surfaceContainerLowest` | `#0B0B12` | самый глубокий слой (подложка модалок) |
| `surface` | `#101018` | фон экрана (сэмпл из templates) |
| `surfaceContainerLow` | `#17171F` | карточки |
| `surfaceContainer` | `#1C1C25` | навигация |
| `surfaceContainerHigh` | `#232330` | диалоги, поиск |
| `surfaceContainerHighest` | `#2D2D3C` | чипы, выделенные плашки |

- Слои строго светлеют от lowest к highest (проверяется тестом `app_theme_test.dart`) — иерархия читается даже без теней.
- Контрастные пары dark: `onSurface` ≥10.4:1, `onSurfaceVariant` ≥7.9:1, `outline` ≥4.2:1 на всех уровнях поверхности — все выше M3-базы (фон глубже → контраст текста выше). Проверяется тестом (обе темы, ≥7:1 / ≥4.5:1).
- Светлая тема **не меняется**: те же роли M3 из seed, без near-black и без glow.

### Градиенты (`AppGradients`, `lib/app/theme/app_tokens.dart`)

Единая точка градиентов; экраны не строят `LinearGradient` руками.

| Токен | Стопы | Роль | Контраст белого текста |
|---|---|---|---|
| `AppGradients.primaryCta` | `#6D46C4` → `#3F5FD9` (фиолет → синий) | primary-CTA («Старт», «Сохранить») | ≥5.4:1 на всей длине (AA) |
| `AppGradients.highlight` | `#6D46C4` → `#C93B8A` (фиолет → розовый) | highlight-вариант (акцентные числа/статистика) | ≥4.6:1 на всей длине (AA) |
| `AppGradients.heroCard` | `#14243D` → `#3A3468` (тёмно-синий → фиолет) | hero-карточка главной (тёмная тема; единственный тёмный градиент, 54.3) | ≥4.5:1 на всей длине (AA, светлый текст) |

Стопы проверяются тестом `app_tokens_test.dart` по всей длине градиента (сэмплы каждые 10%). Белый текст на градиенте — обязательное условие; тёмный текст на градиенте не использовать.

### Glow (`AppGlow`, `AppGlowContainer`)

Неон-обводка и свечение активных элементов. Токены: `AppGlow.radius` (16 — blur), `AppGlow.spread` (2), `AppGlow.alpha` (0.45 — свечение), `AppGlow.borderAlpha` (0.8 — обводка). Компонент `lib/uikit/app_glow_container.dart`.

Правила:
- **Статично:** без анимаций/пульсаций. **Max 1 glow на виджет** — сам контейнер рисует единственную тень.
- Роль — активный/выделенный элемент (текущая тренировка, выбранная карточка). Не подсвечивать несколько элементов декоративно.
- **Тёмная тема — glow (тень + обводка); светлая — только обводка** (без перегрузки светлого фона).
- `intensity` масштабирует альфу (`AppGlow.alpha * intensity`); значения выше 1.0 не нужны — ярче базового свечения не рисуем.

### Pill-кнопки и сегменты

- `AppRadii.pill` (=999, stadium) — токен полного скругления.
- `AppGradientButton`: дефолтный градиент — `AppGradients.primaryCta`; параметры `pill` (stadium вместо `AppRadii.lg`) и `intensity`; glow — только dark; текст всегда белый.
- `AppSegmentedButton<T>` (`lib/uikit/app_segmented_button.dart`) — pill-обёртка над `SegmentedButton` для переключателей (Неделя/Месяц/Год, пол и т.п.): пилюля, текст labelLarge через `AppText`; цвета ролей не переопределяются — M3-дефолт темы (индикатор `secondaryContainer`, текст `onSecondaryContainer`). Сырой `SegmentedButton` вне `lib/uikit/` для новых экранов не использовать; миграция существующих мест — в задачах экранов (54.5–54.9).

### Навигационная оболочка и шапки (54.2)

Нижний `NavigationBar` и `NavigationRail` темизированы в `app_theme.dart` (без правок структуры — IA и состав вкладок не меняются):

- **Pill-индикатор активной вкладки:** `indicatorShape` = `RoundedRectangleBorder(radius: AppRadii.pill)`, `indicatorColor` = `surfaceContainerHighest` (приподнятая поверхность вместо `primaryContainer`).
- **Неон-актив:** иконка выбранного пункта — `primary` (акцент темы), невыбранная — `onSurfaceVariant`; то же для `NavigationRail` (`selectedIconTheme`). Подписи и композиция — M3-дефолт.
- **Плоский бар:** `elevation: 0`, `shadowColor: transparent` — тональная элевация вместо теней.
- **Выбранный пункт списка** (drawer-меню, trailing rail): `listTileTheme.selectedTileColor` = `surfaceContainerHighest` — та же палитра, что у индикатора; `listTileTheme.shape` = stadium (`AppRadii.pill`) — тот же pill-язык формы.

Шапки (`AppTopBar`):

- Обычный заголовок — `headlineMedium` (28/36, по образцам push-экранов); **корневые экраны** передают `large: true` → `displaySmall` (36/44, крупный левый заголовок). Вес обоих — **w600** (semibold — по образцам `templates/`; M3-дефолт w400 визуально легче). Стиль берётся из контекстной темы (локализованной MaterialApp).
- **Двухстрочная обрезка:** строковый заголовок переносится максимум на 2 строки, далее — ellipsis; кегль не уменьшается (единый стиль для заголовков любой длины). Высота шапки динамическая: тулбар подгоняется под замеренный `TextPainter`-текст **по фактическим констрейнтам слота (`LayoutBuilder`), а не по `MediaQuery`** — в wide-раскладке с rail тулбар уже на ширину rail (81–257dp), и по полной ширине окна замер решился бы «1 строка» с обрезкой второй; кламп масштаба 1.34 зеркалит `AppBar`, короткий заголовок — дефолтные `kToolbarHeight`. Механика: `Scaffold` читает `preferredSize` в своём `build` (до `build` дочерней шапки), поэтому `AppTopBar` хранит измерение в холдере и при смене высоты пост-фреймом перестраивает ancestor-`Scaffold` — слот конвергируется на следующем кадре (иначе `Align` внутри `AppBar` растягивает панель ровно до устаревшего `preferredSize` и вторая строка обрезается).
- Шапка «сливается» со scaffold: `surfaceTintColor: transparent`, `scrolledUnderElevation: 0`, фон = `surface`; отступы — дефолтные M3 (единые).
- `large` ставится только на корневых экранах вкладок/меню (home, exercises — вне режима выделения, programs, plan, progress, history, profile, settings); push-экраны — без флага.

### Главная (54.3)

Hero-карточка «активная программа» (`home_screen.dart`, `_ActiveProgramCard`):

- **Тема-сплит градиента:** тёмная тема — токен `AppGradients.heroCard` (тёмно-синий `#14243D` → фиолет `#3A3468`, стопы сэмплированы из образца `templates/IMG_20260920_204544.jpg`), светлые текстовые роли по умолчанию (`onSurface` ≥8.8:1 на светлом стопе); светлая тема — прежний лёгкий градиент ролей (`surfaceContainerLow` → `primaryContainer` ×`AppTints.faint`), тёмные роли по умолчанию. Единственный «тёмный» градиент в `AppGradients` — им покрывается только роль «текущая/ближайшая тренировка».
- **Неон-обводка** — `AppGlowContainer(radius: AppRadii.xl)` вокруг `AppCard` (роль «текущая тренировка»; glow только dark, в light — только обводка, §11).
- **CTA:** полноширинная pill-кнопка `AppGradientButton(pill, icon: play_arrow, label «Начать»)` вместо `IconButton.filledTonal`; рендерится только при наличии ближайшего дня (`onStart != null` — поведение прежнее). Ровно один `Icons.play_arrow` на экране — контракт e2e.
- **Streak-бейдж:** `AppBadge` (pill, `local_fire_department`, фон `primaryContainer` ×`AppTints.faint`, текст `primary`) отдельной строкой над секцией «Последние тренировки»; показывается только при `streakDays >= 1` (правило «без данных — без элементов»). Расчёт — чистая функция `streakDays` (`lib/core/domain/workout_streak.dart`): серия активна, если последняя тренировка сегодня или вчера; прерванная/пустая → 0.
- **Карточка недавней тренировки:** программа/дата/число упражнений слева, крупная длительность `titleLarge` справа (без иконочного бокса и шеврона — тап по всей карточке).

Low из 54.1 закрыты: disabled `AppGradientButton` отличим (подложка `surfaceContainerHigh` вместо градиента, текст `onSurfaceVariant`, без glow; `busy` — отдельное состояние на градиенте со спиннером); `AppGlowContainer` рендерит `AppContainer` вместо сырого `Container`.

### Программы (54.4)

Список программ (`programs_screen.dart`, `_ProgramCard`, образец `templates/IMG_20260920_204537.jpg`):

- **Две колонки через вертикальный разделитель** (`outlineVariant`, `IntrinsicHeight`): слева — `ProgramThumbnail` 56, название `titleLarge` w600 (maxLines 2), дневные бейджи; справа — ближайший день, кольцо прогресса, pill-CTA. Строка метаданных сверху слева: «N дня | M упражнений» — labelSmall `onSurfaceVariant`, letter-spacing 0.4, тонкий разделитель-чертка.
- **Кольцо `AppProgressRing`** (перенесено из home; подпись `%` в `FittedBox(scaleDown)`, `excludeSemantics: true` — иначе label мержится с детским текстом) — недельный прогресс сессий `[пн, пн+7)`; справа дробь `programListWeekFraction` («1/3 дн»). Данных нет (нет `WorkoutRepository`/дней у программы) — кольцо и дробь скрыты («без данных — без элементов»). Расчёт — домен `weeklyProgramProgress` (`lib/core/domain/weekly_progress.dart`), `ProgramListController` получает необязательные `WorkoutRepository` и `clock`.
- **Ближайший день** — compound-строка «Ближайший день: Пн» через `homeUpcomingDay` (без привязок — скрывается; отдельный `find.text('Пн')` не задваивается — бейджи остаются отдельными); расчет — домен `nearestWeekday`.
- **Бейдж «Активная»** — outline-pill: обводка `primary`, текст `primary` labelSmall w600 (вместо залитого).
- **CTA «Начать»** — `AppGradientButton(pill, icon: play_arrow)` в правой колонке, рендерится при наличии дней (поведение прежнее).

**`AppNumberStepper`** (`lib/uikit/app_number_stepper.dart`, новый) — поле-строка ± вместо outlined-поля с цифровой клавиатурой (образец «Параметры упражнения»):

- Контракт `TextFormField` сохранён: лейбл через `labelText` (`find.widgetWithText(TextFormField, label)`), ввод через контроллер (`enterText`), валидация `Form`/`validator`. Валидное значение — без рамки (`enabledBorder: none`), ошибка — красная рамка + текст валидатора; фокус — `outline`.
- Кнопки ± столбиком справа, шаг `step`, кламп по `min` (0 — «−» до нуля, валидатор решает допустимость), `decimals` (вес/дистанция), иконочный бейдж-плашка слева (`icon`), тултипы `commonIncrease`/`commonDecrease`. Живая валидация: `controller.text` → `didChange` → `autovalidateMode.onUserInteraction`.
- Применение: каждая строка-степпер — в `AppCard` (горизонтальный паддинг 12, вертикальный 4), как в образце «Параметры упражнения». Конструктор программы — разминка/отдых (без иконок, валидации не было — `validator: null` сохранён); params — подходы/повторы/вес/время/дистанция/отдых с иконками `format_list_numbered`/`repeat`/`fitness_center`/`timer`/`directions_run`/`hourglass_bottom` и крупным значением titleLarge w600.

Экраны 54.4:

- **Конструктор программы:** «Количество дней» — `AppSegmentedButton<int>` (1–7) вместо сырого `SegmentedButton`; степперы разминка/отдых — в `AppCard` (тот же вид, что на params); новая программа стартует с префиллом дефолтов по образцу — разминка 10, отдых 60 (запись до подписки на контроллеры, форма не «изменённая»); нижний CTA — `AppGradientButton(pill, busy)` («Сохранить» / «Заполнить день N»). Режим удаления дней остаётся `FilledButton` — осознанное delete-исключение; диалоги не тронуты.
- **Наполнение дня:** сегмент основной/альтернативный набор — `AppSegmentedButton<bool>` (expanded), CTA — `AppGradientButton(pill)`.
- **Параметры упражнения (образец 204634):** шапка — `AppCard` с `ExerciseThumbnail(size: 64)` и названием `titleLarge` w600; каждое поле — `AppCard` со степпером (иконочный бейдж типа слева, крупное значение titleLarge w600, ± справа); футер-карточка `AppCard` «Прогресс плана: День N / M» (`exerciseParamsPlanProgress`) + `LinearProgressIndicator` — позиция дня в программе (`getDay` + `getById`), без данных — скрыт; CTA — `AppGradientButton(pill, icon: save)`.

### План (54.5)

Экран «План» (`week_plan_screen.dart`, образец `templates/IMG_20260920_204446.jpg`):

- **Переключатель вида** — `AppSegmentedButton<WeekPlanView>` «Неделя/Месяц» (l10n `progressPeriodWeek`/`progressPeriodMonth`), по умолчанию неделя. Вид — сигнал контроллера `view`; смена вида перезагружает диапазон (`_load` по виду: неделя `[пн, пн+7)`, месяц `[1-е, последний день]`).
- **Месяц** — переиспользуемый календарь `MonthGridView`/`MonthSwitcher`/`MonthDayCell` (`lib/app/widgets/calendar/month_grid.dart`, тот же, что в «Истории»): заголовок `monthTitle` («Август 2026»), ряд будней Пн–Вс (`weekdayMon…Sun`), свайп и стрелки с границами как у недели (51.2: текущий и следующий месяц в пределах данных — до конца следующей недели; `canGoPrevMonth`/`canGoNextMonth`).
- **Ячейка тренировочного дня** — `background: primaryContainer`, `foreground: onPrimaryContainer`, до 2 мини-иконок групп мышц (`MuscleGroupIcon(size: 16)` — минимум читаемости иконок-ассетов по базе 16–18dp; дедупликация по ассету `MuscleGroupIcon.dedupeByAsset` — грудь/пресс один ассет); «сегодня» — glow `AppGlowContainer` + рамка `primary`; выбранный день — акцентная рамка. `MonthDayCell` расширен необязательным `icons` (иконки вместо гантели, когда переданы; ряд иконок в `FittedBox(scaleDown)` — на узких ячейках ≤~380dp масштабируется вместо клипа). Группы резолвит контроллер при загрузке: `muscleKeys` по основным упражнениям дня через `ExerciseRepository.muscleGroupsByExercise`; репозиторий не передан — иконок нет («без данных — без элементов»).
- **Смена периода без pop-in** — `setView`/`shiftMonth` синхронно сбрасывают `items` перед `_load()` (сетка нового периода рисуется по свежим данным, спиннер включается сразу); `refresh()` item'ы не трогает — авто-перезагрузки без мигания.
- **Принятые отклонения (design-review 54.5):** glow «сегодня» рисуется на уровне ячейки — соседние ячейки при 6px-зазоре могут слегка срезать ореол справа/снизу (асимметрия) — принято до визуальной проверки на эмуляторе; тап-таргет ячейки `min(w/7, h/6)` на узких телефонах (<48dp) — общий debt `MonthGridView`, унаследованный из «Истории»; тап по строке времени в карточке месяца ведёт в подготовку (как в недельном превью), не в правку времени; строки карточки без действий визуально идентичны тапабельным (разница — только ripple); ячейки месяца без `Semantics`-подписей (паттерн «Истории»).
- **Карточка дня** под сеткой — `AppCard` (maxHeight 240, внутренний скролл; non-flex ребёнок после `Expanded`-сетки — календарь доминирует, как в образце): дата `d MMMM yyyy` (`ru`) + бейдж «Сегодня» при совпадении, строки тренировок (превью `ProgramThumbnail`, «Программа → День N», время `primary`, `StatusBadge`), пустой день — `weekPlanEmpty`. Тап строки гейтится тем же `dayActionsFor`, что и в недельном виде (47.1): `start` — подготовка, `reschedule` (будущая дата) — с пробросом `rescheduleWeekStart`; строки без действий (выполненные/пропущенные) — информационные, `onTap: null`. Листа действий в месяце нет — это визуальный слой над данными планирования; выбор дня по умолчанию — «сегодня», в чужом месяце — 1-е число (карточка видима всегда).
- **Неделя** — механика и контракты прежние (`_WeekSwitcher`, `_WeekGrid`/`_WeekList`, quick start, лист действий/расписание); состояние ошибки загрузки вынесено в `_buildLoadError` (общий для обоих видов).

### Workout-flow (54.6)

Экраны выполнения тренировки (образцы: подготовка `templates/IMG_20260920_204551.jpg`, run `IMG_20260920_204555.jpg`/`IMG_20260920_204611.jpg`, итоги `IMG_20260920_204558.jpg`/`IMG_20260920_204606.jpg`; образца разминки нет — визуал из токенов редизайна). Механика и e2e-контракты не менялись (guard'ы 53.5 сохранены):

- **Подготовка** (`workout_prepare_screen`): шапка-карточка программы — «Программа: X» (`workoutPrepareProgramLabel`), «День N», прогресс-бар `день/всего дней` (`WorkoutPrepareController.totalDays` из `ProgramRepository.getDays`; при `totalDays <= 0` бар скрыт); список упражнений — карточки с превью `ExerciseThumbnail` (заглушка тип-дифференцирована: strength `fitness_center`, bodyweight `accessibility_new`, plank `self_improvement`, distance `directions_run`), **первое (текущее) упражнение подсвечено** `AppGlowContainer`, остальные приглушённые (secondary-стиль); CTA — pill `AppGradientButton` «Начать тренировку».
- **Разминка** (`workout_warmup_screen`): таймер-карточка `AppContainer` (`surfaceContainerHighest`, счётчик `displayMedium`); кнопки «Пропустить»/«Начать тренировку» без изменений по типам — e2e-контракт (`WorkoutWarmupScreen` + «Пропустить») сохранён.
- **Run** (`workout_run_screen`): механику не тронули; plank-панель «Начать» — pill `AppGradientButton` вместо `FilledButton.icon` (e2e-файндеры переведены на `ElevatedButton`). Поля ввода и «Подход выполнен» (`FilledButton`) — прежние контракты. Карточка «Последний результат» — бейдж цели справа от заголовка (`_goalLabel` по параметрам позиции: `durationSeconds` → «Цель: N с», `reps` → «Цель: N повт» `workoutRunTargetReps`; данных нет — бейджа нет).
- **Итоги** (`_FinishedView`): эмблема-галочка — круглый `AppGlowContainer` с `AppGradients.primaryCta` и `Icons.check`; сводка «N подходов • Время: N мин»; задействованные мышцы — крупные `MuscleGroupIcon(size: 56)` (ключи из `MuscleGroup.key`, дедуп `MuscleGroupIcon.dedupeByAsset`) + чипы названий; streak — badge `AppBadge` (`local_fire_department`, `homeStreakDays`) из `WorkoutRepository.getAllSessions()` → `streakDays(dates, today)`, только при серии ≥1 («без данных — без элементов»); кнопки: «К прогрессу» — pill `AppGradientButton` (→ `/progress`), «Повторить тренировку» — `AppOutlinedButton` (только при `programDayId != null`).
- **Повтор тренировки — перезапуск на месте, без навигации** (`WorkoutRunController.restart()`): `pushReplacement` на тот же путь ненадёжен — go_router при единственном маршруте в стеке (например, восстановление из чекпоинта) возвращает декларативный список с тем же `pageKey`, Navigator переиспользует Element и старый State с фазой `finished` остаётся на экране. `restart()` сбрасывает флаги `saved`/`saving`/мемоизацию `_saveInFlight` и прогоняет `load()` заново — `workout.start` очищает результаты и возвращает фазу `exercise`; guard'ы 53.5 не затронуты.

### Упражнения (54.7)

Экраны упражнений (образцы: список `templates/IMG_20260920_204533.jpg`, форма `IMG_20260920_204618/204614/204622.jpg`; **образца детали нет** — визуал из токенов §11). Функциональность не менялась, обновлены контракты тестов/e2e (`play_arrow`, `SwitchListTile`, `_toggleFormSwitch`):

- **Список** (`exercises_screen`): поиск — `SearchBar` без изменений; фильтры-чипы — пилюли, выбранный оборачивается в `AppGlowContainer` (обводка в светлой, glow в тёмной — дефолт компонента); «Только свои упражнения» — отдельная строка на всю ширину: `AppInkWell` по всей строке + `Switch` с `Semantics(toggled)`, вертикальный padding 12 (тап-таргет ≥48dp); карточка: превью — общий `ExerciseThumbnail(size: 56)` (локальный `_Thumbnail` удалён), бейдж типа — pill, до **3 иконок мышц** `MuscleGroupIcon(size: 18)` с дедупом `dedupeByAsset` (названия строкой ниже, `maxLines: 2` — не обрывается на fontScale 1.3), названия `maxLines: 2`; play — градиентный круг 48dp `AppGradients.primaryCta` + `Icons.play_arrow` + `Tooltip` + `Semantics(button)` (**без glow** — на каждой карточке он конкурирует с primary-FAB, design-review 54.7); FAB «+» — градиентный круг 56dp с `Tooltip` (e2e `byTooltip('Новое упражнение')` сохранён).
- **Деталь** (`exercise_detail_screen`, без образца): превью в `AppCard` (`ClipRRect` xl — без ступеньки радиусов), плейсхолдер превью — иконка по типу упражнения (как в `ExerciseThumbnail`); имя — `headlineMedium` bold (доминанта над служебным заголовком тулбара `headlineMedium`); бейдж типа — pill; схема мышц `MuscleDiagram ×2` (контракт) — в `AppCard`; чипы мышц/противопоказаний — `StadiumBorder` (пилюли). Секции — прежние `AppSection` (контракты заголовков).
- **Форма** (`exercise_form_screen`, по образцу): секции-карточки `_Section` → `AppCard`; порядок — **Медиаматериалы (миниатюра+изображение в одной карточке) → Основная информация (Название*, Тип) → Инструкции (Описание, Техника) → Частые ошибки → Задействованные мышцы → Противопоказания → Режим выполнения**; тумблеры `hideOptional`/`fixedWeight`/`perSide` — `SwitchListTile` с `secondary`-иконками и описаниями (гейты типов 48.5/47.13 сохранены: bodyweight скрывает fixedWeight, distance — perSide); «Добавить ошибку» и CTA «Сохранить» — `AppGradientButton(pill)` (контракт `ElevatedButton` сохранён — градиентная кнопка оборачивает); чипы интенсивности/противопоказаний — `StadiumBorder`; превью-контракты (`Image` ∞×120/160, tooltip «Убрать…», «Выбрать миниатюру/изображение») не менялись. l10n: `exerciseFormMediaSection`, `exerciseFormBasicInfo`, `exerciseFormInstructionsSection`, `exerciseFormMode`.
- **Принятые отклонения (design-review 54.7):** «Интенсивность» в форме — мультивыбор чипами, а не сегмент-пилюля из макета 204622 (модель данных допускает основную+вспомогательную на одну группу); секции формы — `AppCard`-карточки, а не `AppSectionHeader`+divider как в детали (карточный паттерн ближе к образцу 204618); дублирование маппинга «тип → иконка-заглушка» (4-я копия) — WILL ROT, кандидат на общий хелпер в 54.8.

### Прогресс и история (54.8)

Экраны прогресса (образец прогресса — `templates/IMG_20260920_204452.jpg` «Прогресс»; **отдельного образца истории/деталей дня/прогрессии нет** — их визуал собран из токенов §11, композиция/IA не менялась). Функциональность не менялась:

- **Сегмент периода** (`progress_screen`): сырой `SegmentedButton` → `AppSegmentedButton<StatPeriod>` (pill, expanded) — консистентно с 54.5; контракт `find.text('Неделя'/'Месяц'/'Год')` и контроллер не тронуты.
- **Stat-блок → единая градиентная карточка** (решение владельца 2026-10-19): три отдельные `AppCard` слиты в одну — три колонки (Тренировки/Дистанция/Время планки) через вертикальный разделитель (`IntrinsicHeight` + `AppContainer` 1px, паттерн 54.4). Фон по паттерну home-hero 54.3: тёмная тема — токен `AppGradients.heroCard` (светлые роли ≥4.5:1), светлая — токен `AppGradients.roleSurface(colorScheme)` (лёгкий ролевой градиент, общий с hero главной — не дублируется). Разделители: dark — `onSurface` × `AppTints.faint` (outlineVariant светлее роли surface на near-black), light — `outlineVariant`. Тап по «Тренировкам» → `/history` сохранён (e2e-контракт), колонка несёт `Semantics(button)`; значение — `FittedBox(scaleDown)` (не обрезается на fontScale 1.3–1.5), подпись `maxLines: 2`.
- **Бар-чарт «Тренировки по срезам»**: столбики-пилюли (`AppRadii.pill`) градиентом `AppGradients.chartLine` (единый для всех — контраст ≥4.5:1 к карточке, см. §5); **подсветка двух последних непустых срезов** (`counts[i] > 0`) — светлая колонка-подложка `surfaceContainerHigh` (`rangeAnnotations` + хелпер центров `_evenlyGroupCenters`, рисуется до баров) по образцу «выделенных месяцев». Тап по столбику → `/progress/day` (контракт сохранён).
- **Линия метрики и прогрессии упражнения**: `barWidth` 3, градиент `chartLine`, заливка под линией (`belowBarData`, тот же градиент × `AppTints.faint`); **`isCurved: false` — осознанно** (см. §5: кривая искажает значения).
- **История/детали дня/прогрессия** — консервативно: композиция и IA не менялись (без образца — не изобретаем), приведены к токенам (`AppTopBar`, `AppCard`, календарь `MonthDayCell` общий с 54.5).
- **Тесты**: единая градиентная stat-карточка (одна `AppCard`, heroCard в dark, `SemanticsFlag.isButton`), градиенты столбиков/линии по токену, подсветка срезов (`rangeAnnotations`: один непустой срез; «до двух» с пропуском пустых в месячном срезе), заливка под линией, гейтинг «Тренировок → `/history`» (инлайн-GoRouter, без e2e); контраст `chartLine` к карточке обеих тем — автотест `app_tokens_test`.

### Профиль, замеры, здоровье и настройки (54.9)

Финал редизайна (образцы: профиль — `templates/IMG_20260920_204524.jpg`, новый замер — `IMG_20260920_204528.jpg`, моё здоровье — `IMG_20260920_204541.jpg`, настройки — `IMG_20260920_204548.jpg`). Функциональность и IA не менялись:

- **Профиль**: чипы «Текущие значения» — иконка-бейдж метрики слева (`bodyMetricIcon`: рост `height`, вес `monitor_weight_outlined`, обхваты `straighten_outlined` — новых иконок-иллюстраций в ассетах нет) + label сверху/значение снизу по образцу; «История замеров» — заголовок → `AppSectionHeader`, строка — бейдж метрики (весы при известном весе, иначе линейка) + жирная дата; **FAB → градиентная пилюля** по паттерну 54.7 (`AppGlowContainer` + `AppGradients.primaryCta` + `AppInkWell`, иконка+текст; контент — токен `AppColors.primaryCtaContent` (белый: `onPrimary` тёмной темы на градиенте ~2.2:1 — критика дизайн-ревью 54.9, тот же фикс у FAB/ play «Упражнений» и эмблемы итогов 54.6); unit-тест `byType(FloatingActionButton)` → `byTooltip('Добавить замер')`, e2e-текст сохранён); пол → `AppSegmentedButton<Gender>` (нативный `SegmentedButton<Gender>` рендерится внутри — контракт `byType` сохранён; в `AppSegmentedButton` добавлен `emptySelectionAllowed`); график «Динамика» — градиент `AppGradients.chartLine` + заливка `× AppTints.faint`, `barWidth: 3`, `isCurved: false` (паттерн 54.8; `DropdownButton<BodyMetric>`/споты/`fitInside` — контракты не тронуты). ИМТ/ссылки — консервативно (вне образца).
- **Форма замера**: карточки-поля Рост и Вес идут сразу за датой (в образце «Новый замер» секционного заголовка над ними нет — сверху сразу карточка Веса; заголовок «Основные параметры» в коде отсутствует осознанно), каждая — градиентная (dark — `AppGradients.heroCard`, light — `AppGradients.roleSurface`, паттерн 54.8) с бейджем-иконкой и капс-заголовком; секция **«Обхваты (см)»** (`measurementFormGirths`, l10n +1) — сетка 2 колонки (`LayoutBuilder` + `Wrap` с фиксированной шириной колонки) из 8 градиентных карточек-полей. Поля — `floatingLabelBehavior: always` + hint «0.0» (`measurementFormValueHint`) виден без тапа — по образцу (дубль «капс-шапка + лейбл поля» — осознанно по образцу 204528: там оба уровня подписи). Дата-строка и `AppGradientButton` сохранены; `labelText` = `bodyMetricLabel()` — контракт e2e/unit `widgetWithText(TextFormField, 'Рост'/'Вес')` не тронут.
- **Моё здоровье**: info-баннер — `AppContainer` (`surfaceContainerHigh` + `onSurfaceVariant` ≥4.5:1 обеих тем, `info_outline`); каждая строка-тумблер — **отдельная `AppCard`** с иконкой-бейджем тега (`_TagBadge`, `secondaryContainer`) через `SwitchListTile.secondary` (слот `ListTile.leading` при `controlAffinity.platform` — бейдж слева, свитч справа, тап по всей плитке включая бейдж; зазор 8 вместо `Divider`); контракты `byType ×8`/`title as AppText`/e2e `widgetWithText(SwitchListTile, 'Колени')` сохранены. Иконки тегов — осмысленный набор `Icons.*` (`knees→directions_run`, `back→self_improvement`, `neck→face`, `shoulders→accessibility_new`, `elbows→front_hand`, `wrists→back_hand_outlined`, `heart→monitor_heart_outlined`, `pregnancy→pregnant_woman`).
- **Настройки**: каждая секция — **секция-карточка** `AppCard` с `AppSectionHeader` внутри (синк/звук/напоминания/уведомления/тема/о приложении), разрыв «заголовок → контент» унифицирован 8dp; «Синхронизация» — три **плитки** в ряд (`_SyncTile`: `AppContainer` `surfaceContainerHighest` + `AppInkWell`, иконка сверху + подпись; `IntrinsicHeight` + `Row` `crossAxisAlignment: stretch` — равная высота при переносах на крупном шрифте (без `IntrinsicHeight` Row в Column получает бесконечную высоту); disabled — `onTap: null` + `onSurfaceVariant`; тексты/колбэки те же), статус — строка с иконкой (без вложенной карточки), футер — info-баннер (`info_outline`, как в здоровье; `cloud_outlined` убран); «Звук» — тумблер «Звук таймеров» без изменений (e2e-контракт), **строка выбора звука — тайл по образцу**: бейдж-иконка ноты + «Выбрать звук»/имя файла (`maxLines: 1` + ellipsis), play и chevron, **весь тайл тапается** — выбор файла (IconButtons внутри сохраняют собственные жесты; бывшая `AppOutlinedButton`, unit-контракт адаптирован; тултипы сброса/прослушивания и `play_arrow` сохранены); «Уведомления» — контент не менялся (иконка слева + текст, `FilledButton.tonal` — функциональность не трогали); «Тема» → `AppSegmentedButton<ThemeMode>` (expanded, иконки сегментов; `SegmentedButton<ThemeMode>` рендерится внутри — контракт `byType` сохранён); «О приложении» — секция-карточка (вне образца, консервативно).
- **Правило заголовков-пиров** (дизайн-ревью 54.9): секция списка снаружи карточки — `AppSectionHeader` (bold + tracking), заголовок внутри карточки — `titleSmall`; заголовки-пиры одного регистра на экран. **Принятые отклонения Low** (deferred, дизайн-ревью): похожие иконки тегов локтей/запястьев (иллюстраций в ассетах нет), expanded-сегмент темы 40dp (uikit-debt плотности), заливка графика при 1–2 замерах, «Обхваты (см)» sentence case рядом с капсами карточек.
- **320dp**: заголовок карточки обхвата — `Expanded` + `maxLines: 1` + ellipsis (капс «ПРЕДПЛЕЧЬЕ» шире колонки 140px — детерминированное переполнение, WILL BREAK task-review 54.9), guard-тест формы на 320dp.
- **Тесты**: +6 (FAB-пилюля `AppGlowContainer`, бейджи чипов ×8/×2, форма — 10 градиентных карточек + сетка 2 колонки, форма на 320dp без overflow, здоровье — 8 карточек+баннер+бейджи, настройки — секции/плитки/сегмент внутри `AppCard` + info-баннер; unit-контракт `widgetWithText(OutlinedButton, 'Выбрать звук')` → тап по тексту в тайле).

### Одиночные параметры упражнения (55.1)

Экран `/exercises/:id/params` (`single_exercise_params_screen`) — пропуск редизайна, закрыт по паттерну «Параметры упражнения» 54.4:

- Шапка — `AppCard` с `ExerciseThumbnail(size: 64)` и именем `titleLarge` w600 (`maxLines: 2`, ellipsis); поля — степперы `AppNumberStepper` в `AppCard` (горизонтальный паддинг 12, вертикальный 4), иконки `format_list_numbered`/`repeat`/`fitness_center`/`timer`/`directions_run`/`hourglass_bottom`, шаг 0.5 для веса/дистанции; значение — `titleLarge` w600. CTA — `AppGradientButton(pill, icon: play_arrow)`.
- `AppNumberStepper` получил параметр `helperText` (plank-подсказка «Пусто — время удержания со счётчика» — `exerciseParamsHoldHint`, контракт теста) + `helperMaxLines: 2` (обрезка при fontScale ≥1.3 — Medium дизайн-ревью 55.1).
- Контракты не тронуты: `TextFormField`/`labelText`/`enterText`, `ElevatedButton 'Начать тренировку'`, тип-зависимый набор полей, валидации.
- **Нюанс (ленивый список):** карточки укрупнили форму — нижние поля не строятся до прокрутки; в тестах — `scrollFieldIntoView` (`tester.scrollUntilVisible`), проверки шапки/CTA — до скролла.
- Принятые отклонения: без футера «Прогресс плана» (там позиция в программе — здесь одиночный запуск, данных нет); порядок дней в `AppNumberStepper`-кнопках «+» сверху/«−» снизу — общий паттерн uikit. Отложено в 55.4 (task-review 55.1): безопасный парсинг `_start` вместо `int.parse` (WILL COST при ленивом списке + fontScale ≳1.3 — закрывает и эталон 54.4) и выноска общей шапки-карточки/`_buildStepperField` двух params-экранов (WILL ROT).

### Системные мелочи (55.2)

- **Снекбар** (`snackBarTheme`, обе темы): фон `surfaceContainerHighest`, текст `onSurface` (в M3 `ColorScheme` нет `onSurfaceContainerHighest`; на highest-слое контраст ≥10:1 по §11), `behavior: floating`, радиус `AppRadii.lg` — младший радиус шкалы (снекбар — временный мелкий элемент; листы/диалоги — уровень `xxl`, см. ниже). Раньше — M3-дефолт `inverseSurface` выбивался из near-black иерархии.
- **Bottom sheet** (`bottomSheetTheme`, обе темы): фон `surfaceContainerLow`, верхний радиус `AppRadii.xxl` (как у диалогов), `showDragHandle: true` (M3-механика не меняется — листы действий/планирования 54.5 остаются с drag-handle).
- **404** (`not_found_screen`) → `AppEmptyState` (`Icons.search_off` + заголовок «404» + подсказка `errorNotFound`); контракт-тест `router_test` (`'404'` + `'Страница не найдена'`) сохранён без смены l10n.
- **`StatusBadge` — принятый статус** (по §4): chip-радиус `AppRadii.sm`, НЕ pill — статусные бейджи осознанно следуют §4 (Filled/Outlined chip), pill-язык редизайна к ним не применяется. Не трогать.

### Week-plan: pill-CTA «Начать» (55.3)

Primary-действие дня в «Плане» приведено к единому pill-языку редизайна (паттерн 54.4/54.7, токены `AppGradients.primaryCta`/`AppRadii.pill`, §11):

- Обе точки рендера «Начать» — карточка дня (`_WeekList`) и `_DayActionTile` (один и тот же виджет рендерит и bottom-sheet действий дня в месячном виде) — переведены с `FilledButton.tonalIcon` на `AppGradientButton(pill, icon: play_arrow)`; компактный padding стиля убран (пилюля сама задаёт ритм). Иерархия: ровно один primary на блок.
- Вторичные действия не меняются: «Перенести на сегодня» — `FilledButton.tonalIcon`, «Пропустить» — `AppTextButton` (§11, иерархия primary/вторичных).
- Контракты сохранены: текст `'Начать'` виден всем finder'ам (и unit, и e2e); `AppGradientButton` оборачивает `ElevatedButton`, поэтому `widgetWithText(ElevatedButton, 'Начать')`-сценарии e2e не тронуты. Лист действий дня (`_showScheduleSheet` для пустого дня) кнопки «Начать» не содержит — точка одна.
- **Нюанс:** pending-день одиночно не показывает «Перенести» (оно проявляется при втором присвоении того же дня — покрыто тестом 47.3).

### Диалоги и params-формы: унификация (55.4)

Завершение редизайн-языка модалок и снятие отложенных находок ревью 55.1:

- **Диалоги — единый контракт «cancel `AppTextButton` + primary `FilledButton`» (54.6).** Базовый паттерн уже соблюдался большинством диалогов; закрыты два отклонения: диалог переименования дня (primary `AppGradientButton` → `FilledButton` — градиентный CTA в модалках запрещён контрактом 54.6, он только на экранах) и `reminder_time` (ритм трёх actions приведён к образцу диалога выхода из тренировки: cancel слева, primary по центру, деструктивное «Убрать время» — `AppTextButton(destructive: true)` — справа). Остальные диалоги — без изменений.
- **Params-формы — общий компонент.** Шапка-карточка (миниатюра 64 + имя `titleLarge` w600) и поле-степпер вынесены в `features/exercises/ui/exercise_params_form.dart` (`ExerciseParamsHeaderCard`/`ExerciseParamsStepperField`) — единый рендер обоих экранов параметров (одиночный + позиция дня программы), дубль ~50 строк убран. Положение в `features/`, не в uikit: компонент завязан на domain-модель `Exercise`.
- **Безопасный парсинг (WILL COST 55.1).** Ленивый список + крупный шрифт (fontScale ≳1.3) могут размонтировать поле до `validate()` — раньше `int.parse` ронял тап в `FormatException`. Теперь оба экрана парсят через `tryParse` и при нераспарсенном обязательном поле повторно валидируют видимые поля вместо навигации с пустыми данными. На одиночном экране plank-время опционально (счётчик удержания) — guard на него не распространяется.
- **Ревью 55.4:** design-review — инлайн APPROVE без обязательных фиксов (субагент упёрся в лимит использования), **без визуального подтверждения** (эмулятор не запущен): рендер params-форм эквивалентен 55.1 по построению (паритет со скриншотами подтверждён при 55.1), ритмы диалогов — по образцу workout_run exit.

---

### Модальный слой uikit (56.1)

Полная миграция модального слоя в uikit (аудит 2026-10-23: 17 `AlertDialog`/`showDialog` ×11 файлов, 17 `SnackBar`, 27 raw `FilledButton`, 2 `showModalBottomSheet`):

- **Диалоги — `AppDialog` + `showAppDialog`.** `AppDialog` (обёртка `AlertDialog`, только параметры в использовании: `title`/`content`/`actions`/`scrollable`) и `showAppDialog` (обёртка `showDialog`; параметр `barrierDismissible` под единственный сайт «перезапуск после импорта»). Оформление не изменилось — уже токенизировано `dialogTheme` (§11 54.9/55.2). Контракт 54.6 «диалоги → FilledButton» внутри обёртки сохранён: primary теперь `AppButton`, чей сырой виджет — тот же `FilledButton`; finder-контракты `find.byType(...)` не пострадали.
- **Снекбар — `showAppSnackBar(messenger, message)`.** Обёртка `ScaffoldMessengerState.showSnackBar` (тема — `snackBarTheme` 55.2). Аргумент — захваченный `messenger`, чтобы async-gap сайты (`final messenger = ...` до `await`) работали без обращений к контексту; системный вызов — `showAppSnackBar(ScaffoldMessenger.of(context), ...)`.
- **Bottom sheet — `showAppBottomSheet`.** Обёртка `showModalBottomSheet` с `showDragHandle: true` по умолчанию (24 точки 54.5/55.2) и прокидыванием `isScrollControlled`.
- **Отклонение от плана 56.1: `AppFilledButton` не создавался.** Разведка показала, что `AppButton` уже рендерит `FilledButton` де-факто, поэтому новый дублирующий компонент не нужен. Вместо этого `AppButton` расширен: `tonal` (вариант `FilledButton.tonal`/`tonalIcon`), `pending` (спиннер в слоте иконки при сохранении подписи; кнопка неактивна — «проверка обновления» в настройках), `visualDensity`/`padding` (компактный tonalIcon «Перенести» недели). Визуально без изменений.
- **Delete-CTA конструктора программы** (режим удаления, 54.4 — осознанное отклонение от градиента) переведён на `AppButton` — сырого `FilledButton` в features больше нет.

---

### Строчные и тумблерные uikit (56.2)

Строковые/тумблерные компоненты в uikit (32 точки / 12 файлов):

- **`AppListTile` (×16).** Обёртка ListTile: leading/title/subtitle/trailing, `onTap`, `selected`/`selectedTileColor` (задействован adaptive_navigation — pill-фон 54.2), `enabled`, `dense`, `contentPadding`.
- **Итог по этапу:** сырых List/Switch/Checkbox/Dropdown в `lib/features|app` — 0 (34 точки / 13 файлов, калибровка ревью: 2 `DropdownButton` из profile/progress добавлены в объём).
- **`AppSwitchTile` (×8) / `AppCheckboxTile` (×1).** Обёртки SwitchListTile/CheckboxListTile; тумблерные имеют `secondary` (иконка/бейдж-тега, slot по M3), чекбокс-тайл — `controlAffinity: leading` (предупреждения тренировки). Весь тайл тапается (M3), ≥48dp.
- **`AppDropdown` (×4) / `AppDropdownInline` (×2).** Обёртки DropdownButtonFormField/DropdownButton; items описываются через `AppDropdownItem(value, label, labelWidget?)` — сырые `DropdownMenuItem` из call-site'ов ушли (`value: T?` — сигнатура `DropdownMenuItem.value`). Форма — `AppDropdown`: `labelText`/`hintText`, граница `OutlineInputBorder` — как во всех формах, `isDense`/`isExpanded` — параметрами (диалоговые пикеры плотные, поле формы — обычное). Селекторы внутри карточек (метрика профиля, упражнение прогресса — находка ревью, пропущенные аудитом) — `AppDropdownInline`: без подписи и границы, M3-подчёркивание дефолта; `labelWidget` поддерживает ellipsis длинных названий.
- **`AppSwitch` (×1) / `AppCheckbox` (×2).** Голые тумблер-виджеты (строка «Только свои» 54.7, выбор дней/упражнений); колбеки — M3-сигнатуры (`AppCheckbox` несёт `ValueChanged<bool?>?` по API Checkbox, tristate не используется).
- Визуально без изменений; finder-контракты `SwitchListTile`/`ListTile`/dropdown'ов целы (обёртки рендерят голые виджеты).

---

### Кнопки-иконки и тултипы (56.3)

Кнопки-иконки, FAB и тултипы в uikit (39 точек / 15 файлов):

- **`AppIconButton` (×31).** Обёртка IconButton с M3-дефолтами тап-таргета (≥48dp) и отступов; иконка — Widget-пасc-through (`AppIcon`, включая кастомный size 20 в run-подсказке параметров); `tooltip` почти во всех точках (screen reader); `color` (rail-иконка профиля) и `visualDensity` (компактные строки плана и run) — точечные параметры.
- **`AppFab` (×3).** Обёртка FloatingActionButton; `icon: IconData` → `AppIcon` внутри; `heroTag` сохранён (стековая навигация с двумя FAB — уникальные теги `programs-fab`, `program-day-builder-fab`, `stop_sound`), `mini` — компактный run «стоп-звук» (внутри AnimatedScale), `tooltip`. Основные CTA экранов — по-прежнему `AppGradientButton` (54.x); FAB — системные действия списков.
- **`AppTooltip` (×5).** Обёртка Tooltip (аудит насчитывал 6 — точный grep дал 5); пустое `message` — ребёнок напрямую; тултипы вокруг pill-CTA «Добавить» (54.9) и avatar rail сохранены. `find.byType(IconButton/FloatingActionButton/Tooltip)` и `find.text(tooltip)` после long-press — целы.

---

## 12. Чейнджлог

- 2026-10-24 — uikit-миграция 56.3 (§11): кнопки-иконки/тултипы в uikit — `AppIconButton` (31), `AppFab` (3; hero-теги сохранены), `AppTooltip` (5, не 6 по точному grep); 39 точек / 14 файлов. Визуально без изменений; uikit-тесты +9; 1334/1334.
- 2026-10-24 — uikit-миграция 56.2 (§11): строчные/тумблерные в uikit — `AppListTile` (16), `AppSwitchTile` (8) + `AppCheckboxTile` (1), `AppDropdown` (+`AppDropdownItem` — без сырых `DropdownMenuItem`) (4), `AppDropdownInline` (2, находка ревью — селекторы profile/progress), `AppSwitch` (1) / `AppCheckbox` (2); 34 точки / 13 файлов (adaptive_navigation, настройки/звук, напоминания, конструкторы программ, формы упражнений/замеров, week-plan). Визуально без изменений; uikit-тесты +12; 1325/1325.

- 2026-10-24 — uikit-миграция 56.1 (§11): модальный слой в uikit — `AppDialog`/`showAppDialog` (17 диалогов ×11 файлов), `showAppSnackBar` (17 снекбаров; аргумент — захваченный `messenger` для async-gap), `showAppBottomSheet` (2 листа; drag-handle по умолчанию), raw `FilledButton` → `AppButton` (27 точек; компонент расширен `tonal`/`pending`/`visualDensity`/`padding` вместо нового `AppFilledButton` — `AppButton` уже оборачивал `FilledButton`). Визуально без изменений (темы 54.9/55.2 несут оформление); finder-контракты `find.byType` целы, тесты без адаптации. uikit-тесты +13; 1313/1313.
- 2026-10-21 — завершение перевода (задача 55.4, §11): унификация диалогов (переименование дня — `FilledButton` вместо градиента по контракту 54.6; `reminder_time` — ритм cancel|primary|destructive по образцу workout_run exit) + отложенные из 55.1: общий компонент params-форм (`ExerciseParamsHeaderCard`/`ExerciseParamsStepperField`) и безопасный `tryParse`-парсинг в обоих params-экранах (ленивый список + fontScale). Тесты адаптированы ×2; 1300/1300.
- 2026-10-21 — завершение перевода (задача 55.3, §11): week-plan «Начать» → `AppGradientButton(pill, icon: play_arrow)` в обеих точках (`_WeekList`, `_DayActionTile`+bottom-sheet); «Перенести»/«Пропустить» — вторичные, без изменений; текстовые контракты unit/e2e сохранены, +1 тест pill-CTA. 1300/1300.

- 2026-10-21 — завершение перевода (задача 55.2, §11): `snackBarTheme` (`surfaceContainerHighest`/`onSurface`, floating, `AppRadii.lg`) и `bottomSheetTheme` (`surfaceContainerLow`, верхний радиус `AppRadii.xxl`, drag-handle) — токенизированные роли вместо M3-дефолтов, обе темы + тест; 404 → `AppEmptyState` (контракт `router_test` сохранён); `StatusBadge` зафиксирован как принятый chip-статус по §4. Тесты +1; 1299/1299.

- 2026-10-21 — завершение перевода (задача 55.1, §11): экран одиночных параметров `/exercises/:id/params` — единственный пропуск редизайна 54 — приведён к паттерну «Параметры упражнения» 54.4: шапка-карточка `ExerciseThumbnail(64)`+имя `titleLarge` w600, поля — `AppNumberStepper` в `AppCard` с иконочными бейджами, CTA `AppGradientButton(pill)`. `AppNumberStepper` +`helperText` (plank-подсказка, контракт теста). Контракты `TextFormField`/`ElevatedButton 'Начать тренировку'`/валидации не тронуты; тесты +2, ленивый список — `scrollFieldIntoView`. 1298/1298.

- 2026-10-20 — редизайн 54, профиль/замеры/здоровье/настройки (задача 54.9, §11): финал редизайна — профиль (чипы-бейджи `bodyMetricIcon`, `AppSectionHeader` в истории, FAB — градиентная пилюля `AppGlowContainer`+`primaryCta`, пол — `AppSegmentedButton` с новым `emptySelectionAllowed`, график «Динамика» — `chartLine`+заливка), форма замера (градиентные карточки полей heroCard/roleSurface, секция «Обхваты (см)» — сетка 2 колонки; заголовок карточки `Expanded`+ellipsis — 320dp-guard по фиксу WILL BREAK, поля с `floatingLabelBehavior.always`+hint «0.0», l10n +`measurementFormGirths`/+`measurementFormValueHint`), «Моё здоровье» (info-баннер `surfaceContainerHigh`, отдельная карточка на тумблер, бейдж тега через `SwitchListTile.secondary`), «Настройки» (секции-карточки, плитки `_SyncTile` stretch, info-баннер синка, строка выбора звука — тайл с бейджем/play/chevron, весь тайл тапается, сегмент темы expanded). Новый токен `AppColors.primaryCtaContent` (белый контент на `primaryCta`: 2.2:1 у `onPrimary` dark — критика дизайн-ревью; затронуты profile-FAB, exercises FAB/play, эмблема итогов 54.6). Контракты e2e/unit сохранены (`SwitchListTile`×8, `widgetWithText(TextFormField, …)`, `ElevatedButton 'Сохранить'`, `play_arrow`, `SegmentedButton<ThemeMode>/<Gender>`, `DropdownButton<BodyMetric>`); `byType(FloatingActionButton)` и `widgetWithText(OutlinedButton, 'Выбрать звук')` в тестах адаптированы. Тесты: +6; 1296/1296. Ревью: task-reviewer DO NOT SHIP → после фиксов **SHIP**; design-reviewer **APPROVE WITH FIXES** (Critical контраст FAB + Medium закрыты, Low зафиксированы в §11).

- 2026-10-20 — редизайн 54, прогресс и история (задача 54.8, §11): сегмент периода → `AppSegmentedButton` (pill, expanded); stat-блок — три карточки слиты в единую градиентную (тёмная — `AppGradients.heroCard`, светлая — новый токен `AppGradients.roleSurface(colorScheme)` (общий с hero главной 54.3, дубль устранён); три колонки через `IntrinsicHeight`-разделитель, тап «Тренировки» → `/history` + `Semantics(button)`, значение `FittedBox(scaleDown)`); бар-чарт — столбики-пилюли единым токеном `AppGradients.chartLine(brightness)` + подсветка двух последних непустых срезов подложкой-колонкой `surfaceContainerHigh` через `rangeAnnotations` (`VerticalRangeAnnotation`, рисуется ДО баров; `extraLinesData.verticalLines` в BarChart fl_chart не рисуются — issue #1149, выравнивание по центрам групп формулой `spaceEvenly`, хелпер `_evenlyGroupCenters`) по образцу «выделенных месяцев»; линия метрики и прогрессии — градиент `chartLine` + заливка `× AppTints.faint`, `isCurved: false` осознанно (геометрия честная, визуал через градиент — решение владельца 2026-10-19); история/детали дня/прогрессия — композиция не менялась, только токены. Новые токены: `AppGradients.chartLine` (стопы из категориальной палитры серия 0→3, контраст ≥4.5:1 к `surfaceContainerLow` обеих тем — автотест), `AppGradients.roleSurface`. Тесты: +6 (единая stat-карточка heroCard/семантика, градиенты графиков + подсветка одного среза, «до двух» с пропуском пустых, гейтинг «Тренировок → /history» инлайн-роутером, автотесты контраста `chartLine` ×2); 1290/1290.

- 2026-10-19 — редизайн 54.7 «Упражнения» (§11): список — фильтры-пилюли (`AppGlowContainer` у выбранного), «Только свои» отдельной строкой с `Switch`/семантикой `toggled`, play/FAB — градиентные круги (`AppGradients.primaryCta`, play без glow — не конкурирует с FAB), дедуп иконок мышц; деталь — превью в `AppCard` (ClipRRect xl), имя `headlineMedium` bold, бейдж типа pill, чипы-пилюли; форма — секции-карточки `AppCard` с новым порядком по образцу, `CheckboxListTile` → `SwitchListTile` с иконками, CTA `AppGradientButton(pill)`. Контракты: `play_arrow`, `switchInRow(SwitchListTile)`, e2e `_toggleFormSwitch`. l10n: +4 ключа секций формы. Тесты: 1284/1284.

- 2026-10-19 — редизайн 54, упражнения (задача 54.7, §11): список — фильтры-пилюли с glow у выбранного (`AppGlowContainer`), «Только свои упражнения» перенесено из чипов в отдельную строку `AppInkWell`+`Switch` с `Semantics(toggled)` (тап по всей строке, ≥48dp), превью карточки — общий `ExerciseThumbnail(size: 56)` (локальный `_Thumbnail` удалён), до 3 иконок мышц с дедупом `dedupeByAsset`, названия `maxLines: 2`; play — градиентный круг 48dp `play_arrow`+`Tooltip`+`Semantics(button)` без glow (не конкурирует с FAB), FAB — градиентный круг с `Tooltip` (e2e `byTooltip` сохранён). Деталь — превью в `AppCard` (ClipRRect xl), имя `headlineMedium` bold (доминанта над eyebrow-тулбаром), бейдж типа pill, схема мышц в `AppCard`, чипы `StadiumBorder`, плейсхолдер превью по типу. Форма — секции-карточки `AppCard`, порядок по образцу 204618/204614 (Медиаматериалы → Основная информация → Инструкции → Частые ошибки → Мышцы → Противопоказания → Режим выполнения), тумблеры → `SwitchListTile` с иконками/описаниями (гейты типов 48.5/47.13 сохранены), «Добавить ошибку»/«Сохранить» — `AppGradientButton(pill)`, чипы интенсивности/противопоказаний — пилюли; превью-контракты (`Image` ∞×120/160, «Убрать…», «Выбрать…») не менялись. l10n: `exerciseFormMediaSection`, `exerciseFormBasicInfo`, `exerciseFormInstructionsSection`, `exerciseFormMode`. Контракты: play → `play_arrow` ×3, unit `switchInRow(SwitchListTile)`, e2e `_toggleFormSwitch`; отклонения зафиксированы в §11 (мультивыбор интенсивности, карточные секции формы, WILL ROT «иконка типа» → 54.8). Тесты: +8 (тумблер «Только свои», glow-фильтр, дедуп иконок 5→3, секции-карточки, порядок секций, тумблеры с иконками, pill-CTA); 1284/1284.

- 2026-10-18 — редизайн 54, workout-flow (задача 54.6, §11): подготовка — шапка-карточка программы («Программа: X» `workoutPrepareProgramLabel`, «День N», прогресс-бар день/всего — `WorkoutPrepareController.totalDays`, скрыт при 0), список упражнений с превью `ExerciseThumbnail` (заглушка тип-дифференцирована по типу упражнения) и подсветкой текущего (первого) упражнения `AppGlowContainer` (остальные приглушённые), pill-CTA `AppGradientButton`; разминка — таймер-карточка `AppContainer` (`surfaceContainerHighest`, счётчик `displayMedium`), кнопки и e2e-контракт (`WorkoutWarmupScreen`/«Пропустить») без изменений; run — plank-панель «Начать» pill `AppGradientButton` (e2e-файндеры `FilledButton`→`ElevatedButton`), бейдж цели справа от заголовка «Последний результат» (`_goalLabel`: `durationSeconds`→«Цель: N с», `reps`→«Цель: N повт» `workoutRunTargetReps`, нет данных — нет бейджа); итоги — эмблема-галочка (`AppGlowContainer` + `AppGradients.primaryCta` + `Icons.check`), сводка «N подходов • Время: N мин», крупные `MuscleGroupIcon(size: 56)` задействованных мышц (дедуп по ассету) + чипы, streak-бейдж `AppBadge` из истории сессий (`streakDays`, только при серии ≥1), «К прогрессу» — pill `AppGradientButton`, «Повторить тренировку» — `AppOutlinedButton` (только при `programDayId != null`). **Повтор — перезапуск на месте** (`WorkoutRunController.restart()`: сброс `saved`/`saving`/`_saveInFlight`/`_savedDetail`), без навигации: `pushReplacement` на тот же путь при единственном маршруте в стеке возвращает декларативный список с тем же `pageKey` — Navigator переиспользует Element и старый State с фазой `finished` остаётся (воспроизведено и закреплено тестом); foreground service после `stop()` на finished перезапускается `start` (флаг `_foregroundRunning`, иначе `update` — no-op). l10n: `workoutRunRepeat`, `workoutRunTargetReps`, `workoutPrepareProgramLabel`; streak переиспользует `homeStreakDays`. Guard'ы 53.5 (мемоизация `completeAndSave`, `_handlePopRequest`) не тронуты. Тесты: подготовка +4 (прогресс-бар 1/2 и 1/1, подсветка текущего, pill-кнопка), итоги +3 (эмблема/streak/кнопки, отсутствие секции мышц без привязок, ассеты с дедупом), бейдж цели ×2, `restart()` в контроллере ×1; 1277/1277.

- 2026-10-16 — редизайн 54, план (задача 54.5, §11): экран «План» — сегмент `AppSegmentedButton<WeekPlanView>` «Неделя/Месяц» (по умолчанию неделя, l10n `progressPeriod*`), месячный вид по образцу 204446 на переиспользуемом календаре `MonthGridView`/`MonthSwitcher`/`MonthDayCell` (последний расширен необязательным `icons`): ячейки тренировочных дней `primaryContainer` + до 2 мини-иконок групп мышц (резолв `muscleKeys` в контроллере через `ExerciseRepository.muscleGroupsByExercise`, дедуп по ассету `MuscleGroupIcon.dedupeByAsset`), «сегодня» — glow `AppGlowContainer`, выбранный день — акцентная рамка; навигация месяцами в границах данных 51.2 (`canGoPrevMonth`/`canGoNextMonth`, текущий+следующий месяц); карточка дня под сеткой (`AppCard`, non-flex после сетки — календарь доминирует; дата + бейдж «Сегодня», строки тренировок со `StatusBadge`, тап гейтится `dayActionsFor` как в неделе (47.1): `start` — подготовка, `reschedule` (будущие) — с пробросом `rescheduleWeekStart`, строки без действий — `onTap: null`; выбор дня по умолчанию «сегодня», в чужом месяце — 1-е). Недельная механика и контракты сохранены; ошибка загрузки вынесена в `_buildLoadError`. Фиксы по ревью: тап строки карточки гейтится `dayActionsFor` (паритет с 47.1), карточка — non-flex после `Expanded`-сетки (календарь доминирует), fallback выбора — 1-е число; по дизайн-ревью: `setView`/`shiftMonth` синхронно сбрасывают `items` (без pop-in), иконки ячейки 16dp, принятые отклонения зафиксированы в §11 (glow-асимметрия, touch-target debt «Истории», семантика строк). Тесты: контроллер (месяц целиком/границы навигации/выбор дня/`muscleKeys`, сброс `items` при смене периода), экран (сегмент, сетка и индикация, карточка и переход, пустой день, иконки групп, навигация месяцами, гейтинг карточки — выполненная строка без действия / будущая с маркером переноса), `muscle_group_icon_test` (`dedupeByAsset`); 1268/1268.

- 2026-10-16 — редизайн 54, программы (задача 54.4, §11): карточка списка по образцу 204537 — две колонки через вертикальный разделитель, ближайший день compound-строкой (`homeUpcomingDay`), кольцо недельного прогресса `AppProgressRing` + дробь «N/M дн» (домен `weeklyProgramProgress`/`nearestWeekday`; `ProgramListController` — необязательные `WorkoutRepository`/`clock`), outline-бейдж «Активная», pill-CTA «Начать»; новый uikit `AppNumberStepper` (поле-строка ±, живая валидация, иконочный бейдж, тултипы `commonIncrease`/`commonDecrease`) в `AppCard`-строках — разминка/отдых в билдере (префилл дефолтов 10/60 по образцу 204637) и все поля params с иконками типов; `AppSegmentedButton<int>` (количество дней) и `<bool>` (основной/альтернативный набор, expanded); pill-CTA `AppGradientButton` билдера/дня/params (режим удаления — осознанное `FilledButton`-исключение); params — шапка `AppCard` с `ExerciseThumbnail(size: 64)` и футер «Прогресс плана: День N / M» (`exerciseParamsPlanProgress`) с `LinearProgressIndicator`. Тесты: `weekly_progress_test`, `nearest_weekday_test`, `app_progress_ring_test` (5), `app_number_stepper_test` (9); finder'ы `FilledButton`→`ElevatedButton` (params/билдер/day/e2e), `ensureVisible`/`scrollUntilVisible` под более высокой шапкой; 1253/1253.

- 2026-10-15 — редизайн 54, главная (задача 54.3, §11): hero-карточка активной программы — токен `AppGradients.heroCard` (тёмно-синий → фиолет, стопы из образца) в тёмной теме / прежний лёгкий градиент в светлой, неон-обводка `AppGlowContainer`, полноширинная pill-CTA `AppGradientButton` «Начать» вместо `IconButton.filledTonal`; streak-бейдж (`local_fire_department`, только при серии ≥1) над «Последние тренировки», расчёт — чистая функция `streakDays` (домен, unit-тесты) + l10n plural `homeStreakDays`; карточка недавней тренировки — крупная длительность `titleLarge` справа. Low 54.1 закрыты: disabled `AppGradientButton` отличим (нейтральная подложка, `onSurfaceVariant`, без glow), `AppGlowContainer` рендерит `AppContainer`. Тесты: `workout_streak_test.dart`, `home_controller_test.dart` (streakDays), `home_screen_test.dart` (бейдж/CTA), `app_tokens_test.dart` (стопы/контраст heroCard), `app_gradient_button_test.dart` (disabled).

- 2026-10-14 — редизайн 54, навигация и шапки (задача 54.2, §11): pill-индикатор активной вкладки `NavigationBar`/`NavigationRail` (`AppRadii.pill`, фон `surfaceContainerHighest`), неон-актив (иконка выбранного пункта — `primary`), плоский бар без теней, `listTileTheme.selectedTileColor` = `surfaceContainerHighest` + pill-shape (`AppRadii.pill`); шапки — `AppTopBar.large` (`displaySmall` для корневых экранов, `headlineMedium` для push, вес w600 по образцам), двухстрочная обрезка длинных заголовков (maxLines 2 + ellipsis, динамическая высота шапки: `TextPainter`-замер по фактическим констрейнтам слота через `LayoutBuilder` + пост-фрейм-синхронизация `preferredSize` со Scaffold), без surface-tint и скролл-поднятия. Тесты: `app_theme_test.dart`, `adaptive_navigation_test.dart`, `app_top_bar_test.dart`.

- 2026-10-14 — редизайн 54, фундамент (задача 54.1, §11): near-black поверхности тёмной темы (`copyWith` поверх `fromSeed`, акценты seed-фиксированы), токены `AppGradients` (primaryCta, highlight), `AppGlow` + компонент `AppGlowContainer` (glow только dark, статично, max 1), `AppRadii.pill`, `AppGradientButton` (дефолтный градиент из токенов, pill, intensity), `AppSegmentedButton` (pill-обёртка). WCAG-пары обеих тем автотестятся (`app_theme_test.dart`), стопы градиентов — по всей длине (`app_tokens_test.dart`).

- 2026-09-17 — создан документ. Добавлены: статусные токены `statusSkipped*` (нейтральная отмена вместо `error`), токен сетки `chartGrid` (≥3:1), категориальная палитра `ChartSeriesColors` (6 серий, light/dark, WCAG ≥4.5:1, ΔE≥15), карта поверхностей, верификация контраста.