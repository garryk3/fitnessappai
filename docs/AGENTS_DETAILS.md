# docs/AGENTS_DETAILS.md — детали правил для агентов (читается по ссылке из AGENTS.md)

Сюда вынесены разделы `AGENTS.md`, которые нужны не каждой сессии: окружение,
generated-код, протокол `TASKS.md`, запуск тестировщика и дизайн-ревью,
симлинки opencode.

## Окружение

- Android-эмулятор: AVD `Pixel_10_Pro` (x86_64, Android 16, google_apis_playstore) — единственный AVD в `~/.android/avd` (симлинк на `/mnt/D/android-avd`, см. 47.18). adb: `~/Android/Sdk/platform-tools/adb`. Android SDK: `~/Android/Sdk` (platform 36), NDK закреплён на `28.2.13676358` (см. 47.18).
- JDK: Temurin 21.0.5 в `~/jdks/jdk-21.0.5+11` (поддерживается Gradle 9.1). Пин глобальный, на трёх уровнях: `~/.gradle/gradle.properties` → `org.gradle.java.home` (перекрывает автоопределение JDK из Android Studio для всех проектов машины), `JAVA_HOME` + `PATH` в `~/.profile`/`~/.bashrc`, и `flutter config --jdk-dir`.
- **Подводный камень:** bundled `jbr` в Android Studio — это Java 25, а Gradle 9.1 держит максимум Java 24; стоит снять пин, и он подставится, и сборка упадёт с `Could not determine the dependencies of task ':app:compileFlutterBuildDebug'. > Index: 1, Size: 1`. Если каталог с JDK переедет или удалят, `org.gradle.java.home` начнёт указывать в пустоту и вернётся ровно эта же ошибка — чинится восстановлением JDK 21 и возвратом пути в пин.
- **Flutter в CI — плавающий stable, БЕЗ пина** (решение владельца, этап 62.3, 2026-11-13): репо в ногу со стейблом; deprecation-волна (инцидент 2026-11-12 — внезапный подъём stable уронил CI) митигируется оперативным миграционным этапом (как 62.1), не пином. Локальный SDK может отставать от CI — синхронизировать при первых расхождениях гейтов.
- Integration-тесты (`integration_test/`) в CI НЕ прогоняются. Локально — на Linux desktop: `flutter test integration_test -d linux` (измерено 2026-09-26: 20/20 за 7m42s на холодном прогоне с пересборкой desktop-бандла; тёплый прогон не измерялся — закладывайтесь generously). Требуется стаб `StubSoundService` в `pumpApp`.

## Generated code (commit it, CI never regenerates)

- Drift: `lib/core/database/app_database.g.dart` via `dart run build_runner build` (workdir `fitnessappai/`). После изменения схемы — также дамп `drift_schemas/drift_schema_v<N>.json` (`dart run drift_dev schema dump ...`) — миграционных тестов нет, JSON — версионная запись.
- Аннотацию `@DriftDatabase` держать на классе БД, НЕ на top-level `const` — drift_dev 2.34 иначе не видит БД.
- Если `build_runner` после смены схемы отдаёт stale/skipped outputs: `rm -rf .dart_tool/build` и пересборка.
- l10n: `app_localizations*.dart` генерируются из `lib/l10n/app_ru.arb`; коммитятся и исключены из анализа (`flutter gen-l10n` или автозапуск через `generate: true`).

## Вендорный плагин restrict_raw_flutter (история)

Pub-версия 0.2.2 (upstream SoutaTanaka) несовместима с Dart 3.14: SDK-генератор требует `analysis_server_plugin >=0.3.21`, у upstream `<0.3.15` — синтетический pub upgrade падает, плагин молча не грузится; плюс upstream не матчит импорты `package:material_ui` (миграция 62.1). Форк в `vendor/restrict_raw_flutter`: зависимости подняты до `analysis_server_plugin ^0.3.26` / `analyzer ^14`, матчинг расширен на `package:material_ui/` (виджеты и `Color` — по element URI, `Colors` — по import URI). Подключён в `fitnessappai/analysis_options.yaml`; вендор исключён из анализа основного пакета и прогоняется в CI отдельным шагом («Vendor restrict_raw_flutter»: pub get + dart analyze + dart test, 86 тестов).

## Симлинки opencode

`opencode` грузит markdown-агентов только из `.opencode/agents/` (gitignored). Держим их симлинками на `.agents/agents/`, чтобы opencode был синхронен с закоммиченными определениями:

```sh
# from repo root, if .opencode/agents is missing:
mkdir -p .opencode/agents
ln -sf ../../.agents/agents/task-reviewer.md   .opencode/agents/task-reviewer.md
ln -sf ../../.agents/agents/plan-review.md     .opencode/agents/plan-review.md
ln -sf ../../.agents/agents/release-manager.md .opencode/agents/release-manager.md
ln -sf ../../.agents/agents/android-tester.md  .opencode/agents/android-tester.md
ln -sf ../../.agents/agents/design-reviewer.md .opencode/agents/design-reviewer.md
```

## Работа с TASKS.md (входной ящик пользователя)

- `TASKS.md` (repo root) — локальный «ящик» для новых пожеланий: файл в git, содержит шапку-инструкцию; задачи дописываются списком.
- При новом запросе пользователя с задачами (особенно «прочитай TASKS.md / добавь в TASKS.md и выполни»):
  1. Сначала проанализировать задачи и **запланировать**: для каждой — рабочий план в `PLAN.md` (обязательный шаг перед реализацией), продолжая нумерацию этапов/задач.
  2. **Перенести задачи в `PLAN.md`** (секция текущего этапа, задачи `### NN.NN` с рабочими планами).
  3. **Очистить `TASKS.md`** — удалить содержимое, оставив шапку-инструкцию и отметку «задачи перенесены в PLAN.md, этап NN». Файл **не удалять** и **коммитить** вместе с правками PLAN.md.
- Реализация перенесённых задач — по обычной конвенции: ветка `task/NN.NN-<slug>` → PR → зелёный CI → squash merge.

## Как запустить тестировщика (`android-tester`)

- **Короткий прогон (append сценариев):** после задачи с новым функционалом — «запусти android-tester: добавь тест-кейсы для <фича>». Агент только допишет новые сценарии в `TEST_PLAN.md` (TC-<NNN>, шаги, ожидаемый результат), полный прогон НЕ выполняет.
- **Полный QA-прогон:** «запусти android-tester: проверь все экраны» (или конкретную область). Стартует только по требованию пользователя или обязательно перед публикацией релиза. Агент сам поднимет эмулятор, соберёт/установит debug-сборку, обойдёт экраны, придумает stress-сценарии и запишет каждый сценарий в `TEST_PLAN.md`.
- **Задачи на фикс:** после прогона каждый найденный дефект (`FAIL`/`BLOCKED`) агент заводит как новую задачу в `PLAN.md` (продолжая нумерацию, без `✅`) — краткое описание, причина, ссылка на TC. Код не чинит.
- Ручной запуск вне агента: см. `.agents/agents/android-tester.md` (окружение, команды UI-взаимодействия, протокол `TEST_PLAN.md`).

## Как запустить дизайн-ревью (`design-reviewer`)

- Агент `.agents/agents/design-reviewer.md` — ревью UI против `DESIGN.md` по методу скилла `.agents/skills/impeccable` (это скилл, агент ссылается на его критерии): фаза A — дизайн (visual hierarchy, composition, типографика, цвет, состояния, microcopy, affordance, анти-«AI slop»), фаза B — техаудит (a11y/touch targets, theming/хардкод, `restrict_raw_flutter`, перф UI, консистентность с `lib/uikit/`). Вердикт: `APPROVE` / `APPROVE WITH FIXES` / `REDESIGN REQUIRED`.
- Запуск: «запусти design-reviewer: ревью экрана <путь в lib/features/.../ui/>» (или ветки/задачи `NN.NN`). Формат отчёта и правила отсечения находок — в самом агенте; код агент не правит.
- Область ревью по умолчанию (запуск из-под коммита/PR) — **только изменённые и новые UI-файлы задачи** (`git diff --name-status origin/main..HEAD`); полный экран — по запросу владельца.
- В opencode суб-агенты второго уровня недоступны (лимит глубины 1, проверено 2026-10-13) — штатный режим двухфазный инлайн: вывод фазы A фиксируется текстом до детерминированной фазы B; degraded-banner не требуется.
- Скриншоты: если эмулятор доступен (`adb devices`) — агент снимает их сам по протоколу `android-tester`; иначе ревью по коду с явной пометкой «без визуального подтверждения». Полноценное редизайн-ревью экрана — со скриншотами.
