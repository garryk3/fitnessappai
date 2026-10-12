# План разработки FitnessAppAI (Flutter, Android 12+, offline-first)

> Живой план-трекер: **индекс этапов** + **незавершённые/текущие задачи**.
> Завершённые этапы (полные планы и блоки «Реализовано») — в `PLAN_ARCHIVE.md`; переносит туда агент `release-manager` при релизе.
> Стабильный технический контекст (решения, стек, структура, схема БД, seed) — в `docs/PROJECT.md`.
> Процесс разработки, команды и CI — в `AGENTS.md`.

## Как читать этот файл (экономия токенов)

- **Не читай файл целиком.** Найди секцию задачи и читай только её диапазон:
  `grep -n -E '^### NN\.' PLAN.md` → затем `sed -n 'START,ENDp' PLAN.md`.
- Обзор этапов — «Индекс этапов» ниже. История завершённых этапов — `PLAN_ARCHIVE.md` (открывать только при необходимости).
- Технический контекст — `docs/PROJECT.md`; правила процесса — `AGENTS.md`.

## Индекс этапов

Все этапы **0–51** заархивированы в `PLAN_ARCHIVE.md` (там же полные рабочие планы и результаты). Активных этапов нет: новые этапы добавляются сюда по мере поступления из `TASKS.md` (см. `AGENTS.md`), с продолжением нумерации.

| Этап | Название | Задачи | Статус | Завершён (≈) |
|---|---|---|---|---|
| 0 | Подготовка проекта | 0.1–0.6 | ✅ | — |
| 1 | Базовая инфраструктура данных | 1.1–1.4 | ✅ | — |
| 2 | Управление упражнениями | 2.1–2.6 | ✅ | — |
| 3 | Управление программами (тренировочные дни) | 3.1–3.5 | ✅ | — |
| 4 | Выполнение тренировок и расписание | 4.1–4.5 | ✅ | — |
| 5 | Отслеживание прогресса | 5.1–5.3 | ✅ | — |
| 6 | LLM (отложено после MVP) | 6.1–6.6 | ✅ | 2026-08-11 |
| 7 | Профиль, замеры, противопоказания, уведомления, синхронизация | 7.1–7.7 | ✅ | 2026-08-11 |
| 8 | Тестирование и оптимизация | 8.1–8.3 | ✅ | 2026-09-25 |
| 9 | Устранение багов (каждый баг — с тестом на починку) | 9.1–9.6 | ✅ | — |
| 10 | Доработки | 10.1–10.6 | ✅ | — |
| 11 | UX, настройки, домашний экран | 11.1–11.14 | ✅ | — |
| 12 | Доработки по обратной связи | 12.1–12.9 | ✅ | 2026-08-16 |
| 13 | Доработки по обратной связи (вторая волна) | 13.1–13.18 | ✅ | 2026-08-17 |
| 14 | Публикация, лицензия, история упражнений, выполнение по сторонам, таймеры и навигация | 14.1–14.10 | ✅ | 2026-08-17 |
| 15 | Баги и доработки | 15.1–15.38 | ✅ | 2026-08-19 |
| 16 | Доработки UI и UX | 16.1–16.7 | ✅ | 2026-08-21 |
| 17 | Доработки изображений, UX и визуальные фиксы | 17.1–17.10 | ✅ | 2026-08-23 |
| 18 | Исправления и доработки (вторая волна) | 18.1–18.6 | ✅ | — |
| 20 | Исправления расчёта мышц, дней недели и графиков | 20.1–20.5 | ✅ | — |
| 21 | Баг-фиксы и улучшения | 21.1–21.5 | ✅ | — |
| 22 | Баг-фиксы и новые функции | 22.1–22.6 | ✅ | — |
| 25 | Удаление упражнений и сохранение программы с незаполненным днём | 25.1–25.3 | ✅ | 2026-08-28 |
| 26 | План, тренировка, главный экран, редактор программы и звук | 26.1–26.13 | ✅ | 2026-09-01 |
| 27 | Исправление гонки checkpoint при старте тренировки | 27.1 | ✅ | 2026-09-01 |
| 28 | Фоновый режим (сброс/замирание тренировки, аудио-фокус, foreground service) | 28.1–28.6 | ✅ | 2026-09-01 |
| 29 | Баг-фиксы, звук, прогресс, UX-улучшения | 29.1–29.12 | ✅ | 2026-09-01 |
| 30 | План-календарь, назначение плана, напоминания, wakelock, шрифт, audio duck | 30.1–30.7 | ✅ | 2026-09-02 |
| 31 | Мобильные UX-фиксы — настройки, план (неделя), история | 31.1–31.5 | ✅ | 2026-09-03 |
| 33 | Дефекты и фичи — блокировка навигации, изображения, старт, звук | 33.1–33.8 | ✅ | — |
| 34 | Дефекты и фичи — изображения, планирование, замеры, графики, формы | 34.1–34.10 | ✅ | 2026-09-16 |
| 35 | Изображения упражнений, свайп календаря, сплэш | 35.1–35.3 | ✅ | 2026-09-16 |
| 36 | Дизайн-система (внедрение DESIGN.md) | 36.1–36.2 | ✅ | 2026-09-17 |
| 38 | Проверка работоспособности в Android-эмуляторе | 38.1 | ✅ | 2026-09-30 |
| 40 | Новая партия — иконка «+», адаптив, бег/велосипед, метрики-график, «ядро» (backlog на согласование) | 40.1–40.10 | ✅ | 2026-09-23 |
| 41 | Меню-навигация (иконка + rail toggle + 840), bike в программе, унификация календаря, дата в bottom sheet | 41.1–41.4 | ✅ | 2026-09-23 |
| 42 | UI-дефекты навигации/календаря + пункт «Настройки» (ветка task/42-nav-settings-ui-fixes) | 42.1–42.6 | ✅ | 2026-09-24 |
| 43 | 7 дефектов меню/rail, настроек, карточки программы и плана (ветка task/42-nav-settings-ui-fixes, тот же PR #162) | 43.1–43.7 | ✅ | 2026-09-24 |
| 44 | Профиль — пункт меню в шапке rail и drawer (ветка task/42-nav-settings-ui-fixes, тот же PR #162) | 44.1 | ✅ | 2026-09-24 |
| 45 | UI-кит — выделение атомов/молекул в `lib/uikit/` | 45.1–45.9 | ✅ | 2026-09-26 |
| 46 | Уведомления о тренировках в release-сборке (ветка task/46-release-notification-resources) | 46.1–46.10 | ✅ | 2026-09-28 |
| 47 | План недели и уведомления — задачи из TASKS.md (планирование, ветка task/47.0-plan-from-tasks) | 47.0–47.18 | ✅ | 2026-10-06 |
| 48 | Звук уведомлений, прогресс программы, неделя назад, перенос после выполнения, подпись APK, напоминания (задачи из TASKS.md от 2026-09-30) | 48.0–48.12 | ✅ | 2026-10-08 |
| 49 | Процесс ревью и релиза — `task-reviewer` на каждую задачу, `plan-review` перед релизом (обращение владельца в чате, 2026-10-11) | 49.1–49.2 | ✅ | 2026-10-11 |
| 50 | Оптимизация PLAN.md (индекс + архив + `docs/PROJECT.md`) и правило актуализации ветки; фикс date-зависимых e2e переноса дня | 50.1–50.3 | ✅ | 2026-10-11 |
| 51 | Задачи из `TASKS.md` (2026-10-11): версия в настройках, запрет прошлых недель, планирование на занятый день и время, размер ячеек календаря истории, баннер блокировки сна | 51.1–51.6 | ✅ | 2026-10-11 |
| 52 | UI-кит 2.0 — полный запрет сырых Material-виджетов в UI (`restrict_raw_flutter`), весь UI через `lib/uikit/` | 52.1–52.10 | 🚧 | — |

## Незавершённые задачи

### Этап 52 — UI-кит 2.0: полный запрет сырых Material-виджетов в UI (`restrict_raw_flutter`)

**Инициатива владельца (чат, 2026-10-11).** Цель: весь UI строится на компонентах `lib/uikit/`; прямое использование сырых Material-виджетов и сырых цветов вне `lib/uikit/` запрещено анализатором и CI.

**Инструмент:** пакет `restrict_raw_flutter` (`^0.2.2`, MIT, Dart ≥3.10, analyzer plugin). Подключается только в `analysis_options.yaml` (запись в `pubspec.yaml` не нужна). Альтернативу `verita_theme` (гибче, но `0.0.1` и требует `analyzer ^14`) отклонили — начнём с `restrict_raw_flutter`.

**Проверено эмпирически (Flutter 3.47.4 / Dart 3.13.3):**

- `flutter analyze` диагностику плагина показывает **не на всех версиях**: Flutter 3.47.4 (локально, замер 2026-10-11) — 0 issues, 3.47.7 (CI, 2026-10-12) — показывает. Надёжный гейт — `dart analyze --fatal-infos`; в CI оставлены оба шага.
- `dart analyze` по умолчанию возвращает exit 0 даже при info-диагностиках; `dart analyze --fatal-infos` → exit 1. Нужен шаг в CI.
- Подавление — только внутри файла: `// ignore_for_file: restrict_raw_flutter` целиком и `restrict_raw_flutter/*` **не работают**; работает перечисление правил (`restrict_raw_flutter/ban_text_widget, …`) либо `// ignore_for_file: type=lint`.
- Nested `analysis_options.yaml` с `plugins:` анализатором запрещён (`plugins_in_inner_options`).
- `dart analyze --fatal-infos` на текущем коде (без плагина) — чисто → добавление шага безопасно.
- **Гейт нельзя скоупить путём (важно!): `dart analyze lib` плагин НЕ грузит вообще** — 0 диагностик вместо 904 при полном пакете (проверено 2026-10-12). `exclude_for_plugin` не поддерживается, `--options` у `dart analyze` нет → гейт обязан идти по всему пакету, а исключённые каталоги подавляются в самих файлах. Иначе CI молча зелёный без какой-либо проверки (это уже случилось в первой ревизии шага, поймано вручную).
- **Негативный тест гейта в CI (2026-10-12):** временный коммит с `ban_gesture_detector_widget: true` сделал прогон красным (на шаге `Static analysis`, 2 нарушения в `month_grid.dart` и `week_plan_screen.dart`) → гейт реально работает, правило откатили. Попутно выяснилось, что `flutter analyze` на CI-версии Flutter 3.47.7 диагностику плагина показывает (на 3.47.4 — нет), поэтому в CI оба аналитических шага.

**Baseline нарушений.** Плагин регистрирует **18** диагностик (README документирует 16; дополнительно `ban_inkwell_widget` и `ban_gesture_detector_widget`). После исключения `lib/uikit/**`, `lib/app/theme/**`, `test/**`, `integration_test/**` в `lib/` остаётся **703** нарушения в **37** файлах: `ban_text_widget` 385, `ban_icon_widget` 113, `ban_scaffold_widget` 27, `ban_container_widget` 24, `ban_text_button_widget` 24, `ban_listview_widget` 24, `ban_textformfield_widget` 23, `ban_appbar_widget` 23, `ban_card_widget` 22, `ban_inkwell_widget` 12, `ban_outlined_button_widget` 8, `ban_image_widget` 8, `ban_colors` 6, `ban_textfield_widget` 2, `ban_gesture_detector_widget` 2; `ban_color`/`ban_elevated_button_widget`/`ban_gridview_widget` — 0 (все их использования только в `uikit`/`theme`).

**Исключения (сырые виджеты разрешены):** `lib/uikit/**` (там и живут обёртки), `lib/app/theme/**` (дизайн-токены: seed, `ChartSeriesColors`, `chartGrid`), `test/**`, `integration_test/**`. Механизм — `// ignore_for_file: type=lint` в этих файлах (перечень 18 правил нечитаем, а `restrict_raw_flutter`/`restrict_raw_flutter/*` целиком не игнорируются). Гейт идёт по всему пакету (см. п. выше про путь), поэтому тесты и без подавлений провалили бы его. За пределами четырёх исключённых каталогов подавление в `lib/` запрещено CI-шагом «Guard uikit exemptions» (`// ignore_for_file: type=lint` — это же и лазейка в обход запрета).

**Контроль полноты исключений:** включить все 18 правил локально и убедиться, что `dart analyze --fatal-infos` даёт ровно 703 (647 в `lib/features/` + 56 в `lib/app/`, 0 в исключениях), после чего вернуть `false`.

**Правила включаются по мере миграции** (флаги в `analysis_options.yaml`), чтобы CI был зелёным на каждом шаге.

Порядок задач (каждая = ветка `task/52.N-…` → PR → зелёный CI → squash merge):

- [x] **52.1 — Инфраструктура + обёртки uikit** (2026-10-11). Плагин подключён в `analysis_options.yaml` (все `diagnostics: false` — инфраструктура и гейт готовы, нарушений нет). Обёртки в `lib/uikit/`: `AppText` (+`AppText.rich`), `AppIcon`, `AppImage`, `AppContainer`, `AppScaffold`, `AppTopBar` (AppBar), `AppListView`, `AppGridView`, `AppButton` (filled), `AppTextButton`, `AppOutlinedButton`, `AppTextField`, `AppTextFormField`, `AppInkWell`, `AppGestureDetector`, `AppColors` (в т.ч. `transparent`); всё экспортируется из `uikit.dart`. Виджет-тесты обёрток (71). `// ignore_for_file: type=lint` в `lib/uikit/**`, `lib/app/theme/**`, `test/**`, `integration_test/**`. В CI добавлены `dart analyze --fatal-infos` (по всему пакету — см. путь-ловушку выше) и шаг «Guard uikit exemptions»; обновлены `AGENTS.md` (Commands) и `docs/PROJECT.md`.
- [x] **52.2 — Тексты (`Text` → `AppText`), 385 шт.** (2026-10-12). Включено `ban_text_widget: true` (единственное из 18, остальные `false`). Миграция драйвером анализатора: замена строго по позициям line:col из вывода `dart analyze` (не слепым поиском) — 385 замен в 31 файле, включая `const Text(` и единственное `Text.rich` (`exercise_form_screen.dart:372`); в тронутые файлы добавлен package-импорт `uikit.dart`. Два теста с кастами `... as Text` переведены на `AppText`, включая предикат `is Text` внутри `expect(..., findsNothing)` (`adaptive_navigation_test.dart`) — без этого проверка стала бы вакуумной. Гейты: `dart analyze --fatal-infos` = 0 **при включённом правиле**, guard чисто, `flutter test` = 1134/1134. Ревью `task-reviewer` → **SHIP** (в т.ч. доказана байт-эквивалентность нормализованных файлов — чистое переименование). E2E пропущены по согласованию владельца (механическая миграция).
- [x] **52.3 — Иконки (`Icon` → `AppIcon`), 113 шт.** (2026-10-12). Включено `ban_icon_widget: true` (правила накапливаются — `ban_text_widget` из 52.2 остаётся `true`). 113 замен в 25 файлах драйвером `dart analyze` (позиции line:col + проверка границы слова — `IconData`/`IconTheme`/`Icons` не тронуты); package-импорт `uikit.dart` добавлен в 3 файла. **Вынужденное расширение обёртки:** в Flutter 3.47 `Icon.icon` — `IconData?`, а у `AppIcon` был не-null `IconData` → ошибка `argument_type_not_assignable` (`exercises_screen.dart:451`, публичное поле не промотится). `AppIcon` приведён к полной сигнатуре SDK (size/fill/weight/grade/opticalSize/color/shadows/semanticLabel/textDirection/applyTextScaling/blendMode/fontWeight + assert'ы), +2 виджет-теста (null-иконка → пустое место; проброс параметров). Гейты: `dart analyze --fatal-infos` = 0 при **двух** включённых правилах, guard чисто, `flutter test` = 1136/1136. Ревью `task-reviewer` → **SHIP** (сигнатура сверена с SDK побайтово). E2E пропущены по согласованию владельца (2026-10-12).
- [x] **52.4 — Цвета (`Colors.*` → `AppColors`/роли темы), 6 шт.** (2026-10-12). Включены `ban_colors` и `ban_color` (итого 4 из 18: `ban_text_widget`, `ban_icon_widget` — из 52.2/52.3, + эти два; `ban_color` включён «впрок» — baseline по нему 0). **5 механических замен** `Colors.transparent` → `AppColors.transparent` (`adaptive_navigation.dart` ×2, `month_grid.dart`, `profile_avatar.dart`, `muscle_map.dart` — значение по умолчанию параметра), в 2 файла добавлен package-импорт `uikit.dart`. **Одна немеханическая правка:** `Colors.white` текста тултипа fl_chart в `exercise_progression_screen.dart` переведён на роли темы по принятому в проекте паттерну бар-чарта (`progress_screen.dart:269`): `getTooltipColor: inverseSurface` + `TextStyle(onInverseSurface)` (API `LineTouchTooltipData.getTooltipColor` подтверждён в fl_chart 1.2.0). Заодно убран хардкод стиля тултипа: тёмный фон до этого был дефолтом fl_chart (не хардкодом), теперь обе части темозависимы; в светлой теме визуально эквивалентно, в тёмной тултип инвертируется. Гейты: `dart analyze --fatal-infos` = 0 при 4 включённых правилах, guard чисто, `flutter test` = 1136/1136. Ревью `task-reviewer` → **SHIP**. E2E пропущены по согласованию владельца (2026-10-12).
- [x] **52.5 — Карточки и контейнеры (`Card` → `AppCard`, `Container` → `AppContainer`), 46 шт.** (2026-10-12). Включены `ban_card_widget` и `ban_container_widget` (итого 6 из 18). **Развилка решена владельцем (2026-10-12): «всё сразу, единый стиль AppCard»** — визуальные изменения допустимы, полный пасстхру `Card` в `AppCard` не добавлялся. **24 `Container` → `AppContainer`** — механика (полный пасстхру `Container`). **22 `Card` → `AppCard`** с сохранением раскладки: на каждый вызов добавлен `padding: EdgeInsets.zero` (у сырого `Card` паддинг задают дети, у `AppCard` дефолт 16 — ровно 22 шт., подтверждено аудитом ревьюера, ни лишнего, ни пропущенного) и отброшен `margin: EdgeInsets.zero` (нулевой margin давал `cardTheme.margin`). Объединена «оболочка»: радиус 20 + каноническая тень вместо радиуса 16/elevation 2 из `cardTheme`. **`AppCard` расширен двумя параметрами с реальных call-site:** `clipBehavior` (проброс во внешний `Container`, кроп по радиусу 20 — сохранён на все 6 мест с `Clip.antiAlias`) и `color` (фон, `null` → `surfaceContainerLow`; состояние выделения в `exercises_screen`); +2 виджет-теста. Каскад в тестах: `find.byType(Card)` → `find.byType(AppCard)` в 4 файлах (`AppStatCard` нигде не используется — мишени finder'ов подтверждены). `cardTheme` сохранён (сырой `Card` остаётся в `lib/uikit/app_stat_card.dart`). Гейты: `dart analyze --fatal-infos` = 0 при 6 включённых правилах, guard чисто, `flutter test` = 1138/1138. Ревью `task-reviewer` → **SHIP** (аудит аргументов и семантики `Container.clipBehavior` по исходникам SDK). **E2E прогнаны по решению владельца (2026-10-12) и поймали реальный баг, который прошло мимо ревью: `AppCard` рисовал внутри каждой карточки мёртвый `InkWell` (`onTap: null`) — `find.descendant(…, matching: byType(InkWell))` в e2e-тесте «тап по карточке „Тренировок“» находил 2 вместо 1.** Фикс в самой обёртке (решение владельца — в той же задаче): `InkWell` добавляется только при заданном `onTap`, `Material` остаётся всегда (им пользуются дочерние InkWell). Повторный полный e2e: **19/19 PASS** (7м30с), юнит: 1138/1138. Урок: `find.byType(X)` внутри мигрированных обёрток надо проверять на добавление обёрткой собственных виджетов такого же типа.
- [x] **52.6 — Кнопки (`TextButton`/`OutlinedButton`/`ElevatedButton` → `AppTextButton`/`AppOutlinedButton`/`AppButton`), 32 шт.** (2026-10-12). Включены `ban_text_button_widget`, `ban_elevated_button_widget`, `ban_outlined_button_widget` (итого 9 из 18; `ban_elevated_button_widget` — «впрок», 0 сайтов). **Кнопочные обёртки — не пасстхру** (канонические `required label: String`), поэтому 32 сайта перестроены по двум паттернам скриптом с парсингом вызова по скобкам: **A (20)** `XButton(onPressed:, child: AppText(EXPR))` → `AppXButton(label: EXPR, onPressed: …)`; **B (12, `.icon`)** `XButton.icon(onPressed:, icon: AppIcon(ICONS[, size: N]), label: AppText(EXPR[, overflow]))` → `AppXButton(label: EXPR, icon: ICONS[, iconSize: N], onPressed: …)`. **`AppTextButton`/`AppOutlinedButton` получили `iconSize`** (double?, `null` → IconTheme) — сохранение явного `size: 18` на 3 call-site (иначе иконки выросли бы 18 → 24); +1 виджет-тест на обёртку. Осознанно отброшены `overflow: TextOverflow.ellipsis` у 3 лейблов (без `maxLines` — декоративный). `FilledButton`/`.tonalIcon` остаётся сырым — правила среди 18 нет. Каскада в тестах нет (обёртки рендерят голые `TextButton`/`OutlinedButton` внутри — finder'ы тестов и e2e матчат нижележащий виджет). Во время прогона скрипт первый заход сломал синтаксис (терялся хвост после `)` закрывающей строки — запятая-разделитель): файлы откачены, скрипт исправлен, повторный проход чист. Гейты: `dart analyze --fatal-infos` = 0 при 9 включённых правилах, guard чисто, `flutter test` = 1140/1140 (+2 новых теста `iconSize`). Ревью `task-reviewer` → **SHIP** (построчный аудит 32 замен: `onPressed` с `busy ? null : …` сохранён во всех disabled-сайтах). E2E прогнаны по решению владельца (2026-10-12): **19/19 PASS** (7м32с).
- [x] **52.7 — Экран и AppBar (`Scaffold` → `AppScaffold`, `AppBar` → `AppTopBar`), 50 шт.** (2026-10-12). Включены `ban_scaffold_widget`, `ban_appbar_widget` (итого 11 из 18). **27 `Scaffold` → `AppScaffold`** — механика (полный пасстхру; фактические аргументы call-site: `body` 27, `appBar` 23, `bottomNavigationBar` 6, `floatingActionButton` 4, `key` 1, `drawer` 1, `backgroundColor` 1 — все покрыты); `ScaffoldMessenger` цел (граница слова). **23 `AppBar` → `AppTopBar`** — перестройка канонического `title`: `title: AppText(EXPR)` → `title: EXPR` (в т.ч. обе ветви тернарника в `exercises_screen`), `leading` 8 / `actions` 5 проброшены как есть; ревью подтвердило эквивалентность рендера заголовка (тема всегда задаёт `appBarTheme.titleTextStyle`, обёртка передаёт тот же стиль). **Пойман и починен реальный баг (класс WILL BREAK, компилируется чисто):** механическая миграция перенесла `key: _scaffoldKey` (`GlobalKey<ScaffoldState>` из `adaptive_navigation`) на **stateless** `AppScaffold` → `currentState == null` → `_openDrawer()` молча перестал открывать drawer (упал юнит-тест adaptive_navigation). Фикс: `AppScaffold` получил параметр `scaffoldKey` (проброс в `key:` внутреннего `Scaffold`) + регрессионный тест (`currentState` не null + `openDrawer()` реально открывает `Drawer`). Гейты: `dart analyze --fatal-infos` = 0 при 11 включённых правилах, guard чисто, `flutter test` = 1141/1141 (+1 регрессионный). Ревью `task-reviewer` → **SHIP** (построчный байт-эквивалентный аудит 50 замен, сверка с SDK-исходниками по заголовку). E2E прогнаны по решению владельца (2026-10-13): **19/19 PASS** (7м30с). 
- [ ] **52.8 — Списки и изображения (`ListView` → `AppListView`, `GridView` → `AppGridView`, `Image` → `AppImage`), 32 шт.** Включить `ban_listview_widget`, `ban_gridview_widget`, `ban_image_widget`.
  - **Рабочий план (составлен 2026-10-13):** ветка `task/52.8-lists-images` (от 52.7). Baseline по факту: `ListView` 24 (17 конструкторов + 5 `.builder` + 2 `.separated`), `GridView` 0 — правило «впрок», `Image` 8.
  - **Всё механика — обёртки пасстхру с полным набором конструкторов:** `AppListView` имеет `` / `.builder` / `.separated` (те же имена), `AppGridView` — `` / `.builder` / `.count`, `AppImage` — дефолтный с `image: ImageProvider` + все параметры (width/height/fit/errorBuilder/…). Все 8 сайтов `Image(` используют именованный `image: provider` (не `Image.network`), поэтому обычная замена токена корректна; граница слова защищает `ImageProvider`/`AssetImage`.
  - **Каскада в тестах не ожидается и подтверждено по коду:** все три обёртки рендерят голые `ListView`/`GridView`/`Image` внутри → 22 finder'а в тестах и e2e (`byType(Image)` с `tester.widget<Image>`, `byType(ListView)`) продолжают матчить нижележащий виджет. Проверить прогоном.
  - Контроль: `dart analyze --fatal-infos` = 0 при 14 включённых правилах, `dart format`, `flutter analyze`, guard, `flutter test`; далее `task-reviewer` → вопрос про e2e → PR.
- [ ] **52.9 — Поля ввода (`TextFormField`/`TextField` → `AppTextFormField`/`AppTextField`), 25 шт.** Включить `ban_textfield_widget`, `ban_textformfield_widget`.
- [ ] **52.10 — Нажатия (`InkWell` → `AppInkWell`, `GestureDetector` → `AppGestureDetector`), 14 шт.** Включить `ban_inkwell_widget`, `ban_gesture_detector_widget`. Финал: все 18 правил `true`, `dart analyze --fatal-infos` чисто, `lib/uikit/` — единственная точка с сырыми виджетами.
