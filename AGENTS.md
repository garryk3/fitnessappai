# AGENTS.md

## Repo layout (explicit paths — don't guess, paths matter)

- **Git repo root** (all `git` operations, `PLAN.md`, `AGENTS.md`, `DESIGN.md` live here):
  `/home/igor/agent_workspace/projects/fitnessappai`
  This is `git rev-parse --show-toplevel`. Do NOT assume a subdirectory is the root.
- **Flutter package** (the actual Dart/Flutter project — `pubspec.yaml`, `lib/`, `test/`, `integration_test/`):
  `/home/igor/agent_workspace/projects/fitnessappai/fitnessappai`
  All `flutter`/`dart` commands must run with `workdir: fitnessappai/fitnessappai` (CI sets `working-directory: fitnessappai`).
  - `git` commands work from anywhere under the repo root; `../PLAN.md` relative to the package is the SAME file.
- **`PLAN.md`** (repo root): живой трекер — «Индекс этапов» + текущий этап (незавершённые задачи). Завершённые этапы (полные планы и блоки «Реализовано») — в `PLAN_ARCHIVE.md`; стабильный технический контекст (решения, стек, структура, схема БД, seed) — в `docs/PROJECT.md`. **Не читай `PLAN.md` целиком** — найди секцию задачи (`grep -n -E '^### NN\.' PLAN.md`) и прочитай только её диапазон (`sed -n 'A,Bp' PLAN.md`). Обновляй статус задачи (`[x]` + дата) при завершении. Russian language.
- **`TASKS.md`** (repo root, в git): входной «ящик» пользователя для новых пожеланий (см. `## Работа с TASKS.md`).
- **`PLAN_ARCHIVE.md`** (repo root): архив завершённых этапов 0+ — полные рабочие планы и блоки «Реализовано». Читать только при необходимости (файл большой).
- **`docs/PROJECT.md`** (repo root): стабильный техконтекст (решения по проекту, окружение, стек, структура, схема БД, каталог мышц, seed) — вынесен из `PLAN.md`.
- `docs/llm_contract.md`: contract for the LLM content-generation interface (future tasks 6.2–6.6).
- `lib/uikit/` (inside Flutter package): единый источник базовых UI-компонентов (`AppCard`, `AppSection`, `AppSectionHeader`, `AppGradientButton`, `AppStatCard` и др.) — в приоритете при построении UI (см. `## Workflow & conventions`).
- `.agents/` is the shared, version-controlled location for cross-tool agent assets:
  - `.agents/rules/FLUTTER.md` — style/state-mgmt rules (loaded via `opencode.json` `instructions`). Follow it: native-first state (signals, `ChangeNotifier`, `ValueNotifier`), no Riverpod/Bloc/GetX, MVVM, manual DI.
  - `.agents/skills/<name>/SKILL.md` — reusable agent skills (opencode + other tools).
  - `.agents/agents/*.md` — reusable subagent definitions (`task-reviewer`, `plan-review`, `release-manager`, `android-tester`, `design-reviewer`), consumable by other agent solutions.
- `opencode` loads its markdown agents only from `.opencode/agents/` (gitignored). Symlink them to `.agents/agents/` so opencode stays in sync with the committed definitions:
  ```sh
  # from repo root, if .opencode/agents is missing:
  mkdir -p .opencode/agents
  ln -sf ../../.agents/agents/task-reviewer.md  .opencode/agents/task-reviewer.md
  ln -sf ../../.agents/agents/plan-review.md    .opencode/agents/plan-review.md
  ln -sf ../../.agents/agents/release-manager.md .opencode/agents/release-manager.md
  ln -sf ../../.agents/agents/android-tester.md  .opencode/agents/android-tester.md
  ln -sf ../../.agents/agents/design-reviewer.md .opencode/agents/design-reviewer.md
  ```
- `TEST_PLAN.md` (repo root): накопительный ручной тест-план. Ведётся агентом `android-tester` (см. `.agents/agents/android-tester.md`, а также раздел «Как запустить тестировщика» в этом файле).

## Commands (CI in `.github/workflows/ci.yml` is the source of truth)

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test tool integration_test
flutter analyze --fatal-infos
dart analyze --fatal-infos   # гейт правил restrict_raw_flutter (этап 52). Путь НЕ передавать — `dart analyze lib` плагины не грузит; `flutter analyze` видит их не на всех версиях (3.47.4 — нет, 3.47.7 — да)
flutter test
flutter build apk --debug
```

- Single test: `flutter test test/<path>_test.dart`.
- Integration tests (`integration_test/`) are NOT run in CI. They run on Linux desktop: `flutter test integration_test -d linux` (measured 2026-09-26: 20/20 passed in 7m42s **on a cold run that rebuilds the desktop bundle**; a warm re-run was not measured, so budget generously. Requires the `StubSoundService` stub registered in `pumpApp`).
- Environment: native Ubuntu (no WSL). Android emulator available: AVD `Pixel_10_Pro` (x86_64, Android 16) — единственный AVD в `~/.android/avd` (симлинк на `/mnt/D/android-avd`, см. 47.18). adb: `~/Android/Sdk/platform-tools/adb`. Android SDK: `~/Android/Sdk` (platform 36), NDK закреплён на `28.2.13676358` (см. 47.18).
- JDK: Temurin 21.0.5 в `~/jdks/jdk-21.0.5+11` (LTS, поддерживается Gradle 9.1). Локальный `flutter build apk` **работает** (проверено: ~40 с), падать больше нечему. Пин глобальный, на трёх уровнях: `~/.gradle/gradle.properties` → `org.gradle.java.home` (перекрывает автоопределение JDK из Android Studio для всех проектов машины), `JAVA_HOME` + `PATH` в `~/.profile`/`~/.bashrc`, и `flutter config --jdk-dir`. **Подводный камень:** bundled `jbr` в Android Studio — это Java 25, а Gradle 9.1 держит максимум Java 24; стоит снять пин, и он подставится, и сборка упадёт с `Could not determine the dependencies of task ':app:compileFlutterBuildDebug'. > Index: 1, Size: 1`. Если каталог с JDK переедет или удалят, `org.gradle.java.home` начнёт указывать в пустоту и вернётся ровно эта же ошибка — чинится восстановлением JDK 21 и возвратом пути в пин.
- Stack: Flutter/Dart, `drift` ORM, `signals`/`signals_flutter`, `go_router`, `fl_chart`, `flutter_localizations` (template `lib/l10n/app_ru.arb`).

## Generated code (commit it, CI never regenerates)

- Drift: `lib/core/database/app_database.g.dart` via `dart run build_runner build`. After changing table schemas also regenerate the schema dump `drift_schemas/drift_schema_v1.json` (`dart run drift_dev schema dump ...`) — no migration test exists, the JSON is the versioned record.
- l10n: `app_localizations*.dart` generated from `app_ru.arb`; committed and excluded from the analyzer (`flutter gen-l10n`, or auto-run on build via `generate: true`).

## Workflow & conventions

- Repo language is Russian: PLAN.md, commit messages, UI strings. Write commit messages as `task/NN.NN: <краткое описание на русском> (#PR)`.
- **Before opening a pull request, ask the user whether to run the e2e tests** (`integration_test/app_flow_test.dart` via `flutter test integration_test -d linux`; 7+ min on a cold run per the measurement above, not in CI). The user may opt out; never run them silently or skip the question.
- **Перед публикацией релизного тега уточните у владельца (в чате), нужно ли запускать android-tester для проверки релиза в эмуляторе** (полный QA-прогон по `TEST_PLAN.md`, ~час; иначе релиз идёт на unit-тестах и CI). Отказ владельца не прерывает публикацию; молча пропускать вопрос нельзя.
- Each task = branch `task/<NN>-<slug>` from `main` → PR → green CI → squash merge, in dependency order.
- **Перед коммитом/PR актуализируй ветку задачи с `origin/main`: `git fetch origin && git merge origin/main`** (никогда не `rebase`). Причина: в этом репо `rebase`/устаревшая ветка неоднократно роняла строки `PLAN.md`, ломала синхронизацию `dart format`/l10n и оставляла ветку рассинхронизированной с `origin/main` — незаметно до CI/e2e. Реальный diff против `main` — только фактически изменённые файлы (`git diff --name-status origin/main..HEAD`); прочие расхождения — следствие устаревшей ветки, их надо согласовать, а не коммитить.
- **Состояние задачи в `PLAN.md` — до открытия PR, а не после.** Статус `[x]` с датой, блок «Реализовано», отклонения от плана — фиксируются в ветке задачи **до** `git branch -D … gh pr create`; PLAN-правки входят в сам PR (или пушатся в main строго до слияния). Не оставлять «задача слита, а PLAN.md ждёт обновления» — план на момент PR обязан отражать фактическое состояние задачи.
- **После реализации задачи, перед коммитом/PR, запускайте агента `task-reviewer`** (`task-reviewer`) — ревью реализации: (1) соответствие требованиям — diff сверяется с рабочей планом задачи в `PLAN.md`; (2) архитектура — соответствие `.agents/rules/FLUTTER.md` и конвенциям репозитория (`lib/uikit/`, generated-код, l10n); (3) наличие ошибок (tier-система WILL BREAK / WILL COST / WILL ROT). При вердикте `DO NOT SHIP` коммит/PR блокируются.
  - **Исключение:** задачи, которые **только** переносят пожелания из `TASKS.md` в `PLAN.md` (чистка ящика, рабочие планы, разбор развилок) и не меняют код, `task-reviewer` не запускают — проверять там нечего. На такие задачи агент всё равно смотрит сам: этап добавлен в таблицу, у каждой новой задачи есть раздел с планом, `TASKS.md` очищен по правилу ниже. Начиная с задач, где есть изменения в `lib/`, `test/`, `android/` или `pubspec.yaml`, правило действует в полном объёме.
- **Если задача меняет интерфейс приложения (изменённые или добавленные UI-файлы в `lib/`), перед коммитом/PR запускайте агента `design-reviewer`** — область ревью **только изменённые и новые файлы** по `git diff --name-status origin/main..HEAD` (новые экраны/виджеты — целиком, изменённые — по фактическим правкам), а не весь экран или приложение целиком. Задачи без UI-изменений (логика, тесты, доки, CI) — не запускать. Вердикт `REDESIGN REQUIRED` блокирует PR (как `DO NOT SHIP` у `task-reviewer`).
- **Перед релизом запускайте агента `plan-review`** — проверка `PLAN.md`: (1) задача записана в `PLAN.md` со статусом `[x]` и датой завершения; (2) если для задачи составлялся рабочий план, он записан в `PLAN.md`. При провале любой из проверок релиз блокируется. (Перенесено с «перед каждым коммитом» на релизный гейт 2026-10-11, задача 49.1.)
- **После релиза `release-manager` сжимает `PLAN.md`:** завершённые этапы переносятся в `PLAN_ARCHIVE.md`, «Индекс этапов» и нумерация сохраняются, текущий этап остаётся в `PLAN.md`. Стабильные разделы — `docs/PROJECT.md`. Так `PLAN.md` не растёт бесконечно (см. шаг «Сжатие `PLAN.md`» в `.agents/agents/release-manager.md`).
- **After composing a work plan for a task, always write it into `PLAN.md`** (в секцию текущего этапа) before implementation begins — plan must exist in the file before code changes start.
- Keep the `@DriftDatabase` annotation on the database class, NOT on a top-level `const` — drift_dev 2.34 fails to detect the DB otherwise.
- If `build_runner` reports stale/skipped outputs after a schema change, `rm -rf .dart_tool/build` and rebuild.
- **After finishing a task with new functionality, run the `android-tester` subagent to APPEND test cases to `TEST_PLAN.md`** (короткий прогон: только добавить сценарии для нового функционала по протоколу — TC-<NNN>, шаги, ожидание). **Не запускать полный прогон всех сценариев** — полный QA-прогон стартует только по требованию пользователя или обязательно перед публикацией релиза.
- **UI опирается на `lib/uikit/`** — единый источник базовых компонентов (`AppCard`, `AppSection`, `AppSectionHeader`, `AppGradientButton`, `AppStatCard`, `AppBadge`, `AppTile`, `AppThumbnail`, `AppEmptyState`). При создании нового или обновлении существующего UI отдавать приоритет компонентам uikit перед ручным дублированием: заголовки секций — `AppSectionHeader`/`AppSection` (не `Text(... titleMedium)`), primary CTA — `AppGradientButton`, карточки/списки — `AppCard`/`AppTile`. Контекстные виджеты — в `features/<feature>/ui/`. Исключения (delete-действия и т.п.) — осознанно, с пометкой в PR.
- **Сырые Material-виджеты запрещены вне `lib/uikit/` (этап 52).** Пакет `restrict_raw_flutter` (analyzer-плагин, настроен в `fitnessappai/analysis_options.yaml`) запрещает `Text`, `Icon`, `Container`, `Card`, `Scaffold`, `AppBar`, `ListView`, `GridView`, `Image`, `TextField`, `TextFormField`, `TextButton`/`OutlinedButton`/`ElevatedButton`, `InkWell`, `GestureDetector`, а также `Colors.*`/`Color(...)`. Вместо них — обёртки uikit: `AppText`, `AppIcon`, `AppContainer`, `AppCard`, `AppScaffold`, `AppTopBar`, `AppListView`, `AppGridView`, `AppImage`, `AppTextField`, `AppTextFormField`, `AppTextButton`/`AppOutlinedButton`/`AppButton`, `AppInkWell`, `AppGestureDetector`, `AppColors`. **Проверяется только `dart analyze --fatal-infos`** (в CI отдельным шагом, плюс дубль в `flutter analyze`) — `flutter analyze` диагностику плагина видит не на всех версиях (3.47.4 — нет, 3.47.7 в CI — да), а **путь аргументом передавать НЕЛЬЗЯ** (`dart analyze lib` плагин не грузит вообще). Сырые виджеты разрешены в `lib/uikit/**`, `lib/app/theme/**`, `test/**`, `integration_test/**` (там `// ignore_for_file: type=lint` — у плагина нет исключений по путям); в остальных файлах `lib/` подавление запрещено CI-шагом «Guard uikit exemptions». Правила включаются по мере миграции (см. `PLAN.md`, этап 52).
- **Сырые интерактивные M3-виджеты также запрещены вне `lib/uikit/` (этап 56, CI-гейт «Guard raw interactive widgets»).** Запрещены `AlertDialog`, `SnackBar`, `FilledButton`, `IconButton`, `ListTile`, `SwitchListTile`, `CheckboxListTile`, `DropdownButton`/`DropdownButtonFormField`/`DropdownMenuItem`, `FloatingActionButton`, `CircularProgressIndicator`, `LinearProgressIndicator`, `RefreshIndicator`, `Divider`/`VerticalDivider`, `Chip`, `Tooltip`, `Checkbox`, `Switch`, `Drawer`, `PopupMenuButton`/`PopupMenuItem`, а также вызовы `showDialog`/`showModalBottomSheet`. Вместо них — обёртки uikit: `AppDialog`/`showAppDialog`/`showAppSnackBar`/`showAppBottomSheet`, `AppButton` (рендерит `FilledButton`), `AppIconButton`/`AppFab`/`AppTooltip`, `AppListTile`/`AppSwitchTile`/`AppCheckboxTile`/`AppSwitch`/`AppCheckbox`, `AppDropdown`/`AppDropdownItem`/`AppDropdownInline`, `AppSpinner`/`AppLinearProgress`, `AppRefresh`, `AppDivider`/`AppVerticalDivider`, `AppChip`, `AppDrawer`, `AppPopupMenuButton`/`AppPopupMenuItem`. Гейт — grep с word-boundary в CI (список идентификаторов — в шаге `.github/workflows/ci.yml`); зоны `lib/uikit/**`, `lib/app/theme/**`, `test/**`, `integration_test/**` и generated-файлы исключены.

## Работа с TASKS.md (входной ящик пользователя)

- `TASKS.md` (repo root) — локальный «ящик» пользователя для новых пожеланий: файл в git, содержит шапку-инструкцию; задачи дописываются списком.
- При новом запросе пользователя с задачами (особенно «прочитай TASKS.md / добавь в TASKS.md и выполни»):
  1. Сначала проанализировать задачи и **запланировать**: для каждой — рабочий план в `PLAN.md` (обязательный шаг перед реализацией, см. `## Workflow & conventions`), продолжая нумерацию этапов/задач.
  2. **Перенести задачи в `PLAN.md`** (секция текущего этапа, задачи `### NN.NN` с рабочими планами).
  3. **Очистить `TASKS.md`** — удалить содержимое, оставив шапку-инструкцию и отметку «задачи перенесены в PLAN.md, этап NN». Файл **не удалять** и **коммитить** вместе с правками PLAN.md.
- Реализация перенесённых задач — по обычной конвенции: ветка `task/NN.NN-<slug>` → PR → зелёный CI → squash merge.

## Testing quirks

- Unit/widget tests mirror `lib/` under `test/`. DB-dependent tests construct `AppDatabase(executor: NativeDatabase.memory())`.
- Tests assert on `AppLocalizations` Russian strings (`app_ru.arb`).

## Как запустить тестировщика (`android-tester`)

- **Короткий прогон (append сценариев):** после задачи с новым функционалом — «запусти android-tester: добавь тест-кейсы для <фича>». Агент только допишет новые сценарии в `TEST_PLAN.md` (TC-<NNN>, шаги, ожидаемый результат), полный прогон НЕ выполняет.
- **Полный QA-прогон:** «запусти android-tester: проверь все экраны» (или конкретную область). Стартует только по требованию пользователя или обязательно перед публикацией релиза. Агент сам поднимет эмулятор, соберёт/установит debug-сборку, обойдёт экраны, придумает stress-сценарии и запишет каждый сценарий в `TEST_PLAN.md`.
- **Задачи на фикс:** после прогона каждый найденный дефект (`FAIL`/`BLOCKED`) агент заводит как новую задачу в `PLAN.md` (продолжая нумерацию, без `✅`) — краткое описание, причина, ссылка на TC. Код не чинит.
- Эмулятор: AVD `Pixel_10_Pro` (x86_64, Android 16). adb: `~/Android/Sdk/platform-tools/adb`. Учётная запись на эмуляторе — google_apis_playstore.
- Ручной запуск вне агента: см. `.agents/agents/android-tester.md` (окружение, команды UI-взаимодействия, протокол `TEST_PLAN.md`).

## Как запустить дизайн-ревью (`design-reviewer`)

- Агент `.agents/agents/design-reviewer.md` — ревью UI против `DESIGN.md` по методу скилла `.agents/skills/impeccable` (это скилл, агент ссылается на его критерии): фаза A — дизайн (visual hierarchy, composition, типографика, цвет, состояния, microcopy, affordance, анти-«AI slop»), фаза B — техаудит (a11y/touch targets, theming/хардкод, `restrict_raw_flutter`, перф UI, консистентность с `lib/uikit/`). Вердикт: `APPROVE` / `APPROVE WITH FIXES` / `REDESIGN REQUIRED`.
- Запуск: «запусти design-reviewer: ревью экрана <путь в lib/features/.../ui/>» (или ветки/задачи `NN.NN`). Формат отчёта и правила отсечения находок — в самом агенте; код агент не правит.
- Область ревью по умолчанию (запуск из-под коммита/PR) — **только изменённые и новые UI-файлы задачи** (`git diff --name-status origin/main..HEAD`); полный экран — по запросу владельца. Обязательность запуска и блокирующий вердикт — в `## Workflow & conventions`.
- В opencode суб-агенты второго уровня недоступны (лимит глубины 1), поэтому метод — двухфазный инлайн: вывод фазы A фиксируется текстом до детерминированной фазы B; это штатный режим, degraded-banner не требуется.
- Скриншоты: если эмулятор доступен (`adb devices`) — агент снимает их сам по протоколу `android-tester`; иначе ревью по коду с явной пометкой «без визуального подтверждения». Полноценное редизайн-ревью экрана — со скриншотами.
- Вердикт `REDESIGN REQUIRED` блокирует PR с UI-изменениями (как `DO NOT SHIP` у `task-reviewer`).
