# AGENTS.md

## Repo layout (explicit paths — don't guess, paths matter)

- **Git repo root** (all `git` operations, `PLAN.md`, `AGENTS.md`, `DESIGN.md` live here):
  `/home/igor/agent_workspace/projects/fitnessappai`
  This is `git rev-parse --show-toplevel`. Do NOT assume a subdirectory is the root.
- **Flutter package** (the actual Dart/Flutter project — `pubspec.yaml`, `lib/`, `test/`, `integration_test/`):
  `/home/igor/agent_workspace/projects/fitnessappai/fitnessappai`
  All `flutter`/`dart` commands must run with `workdir: fitnessappai/fitnessappai` (CI sets `working-directory: fitnessappai`).
  - `git` commands work from anywhere under the repo root; `../PLAN.md` relative to the package is the SAME file.
- **`PLAN.md`** (at repo root, path `PLAN.md` in git): task tracking with `[x]` statuses + progress table. Update it whenever a task is done. Russian language. It lives at the repo root, NOT inside the Flutter package.
- `docs/llm_contract.md`: contract for the LLM content-generation interface (future tasks 6.2–6.6).
- `lib/uikit/` (inside Flutter package): единый источник базовых UI-компонентов (`AppCard`, `AppSection`, `AppSectionHeader`, `AppGradientButton`, `AppStatCard` и др.) — в приоритете при построении UI (см. `## Workflow & conventions`).
- `.agents/` is the shared, version-controlled location for cross-tool agent assets:
  - `.agents/rules/FLUTTER.md` — style/state-mgmt rules (loaded via `opencode.json` `instructions`). Follow it: native-first state (signals, `ChangeNotifier`, `ValueNotifier`), no Riverpod/Bloc/GetX, MVVM, manual DI.
  - `.agents/skills/<name>/SKILL.md` — reusable agent skills (opencode + other tools).
  - `.agents/agents/*.md` — reusable subagent definitions (`plan-review`, `release-manager`, `android-tester`), consumable by other agent solutions.
- `opencode` loads its markdown agents only from `.opencode/agents/` (gitignored). Symlink them to `.agents/agents/` so opencode stays in sync with the committed definitions:
  ```sh
  # from repo root, if .opencode/agents is missing:
  mkdir -p .opencode/agents
  ln -sf ../../.agents/agents/plan-review.md   .opencode/agents/plan-review.md
  ln -sf ../../.agents/agents/release-manager.md .opencode/agents/release-manager.md
  ln -sf ../../.agents/agents/android-tester.md  .opencode/agents/android-tester.md
  ```
- `TEST_PLAN.md` (repo root): накопительный ручной тест-план. Ведётся агентом `android-tester` (см. `.agents/agents/android-tester.md`, а также раздел «Как запустить тестировщика» в этом файле).

## Commands (CI in `.github/workflows/ci.yml` is the source of truth)

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test tool integration_test
flutter analyze --fatal-infos
flutter test
flutter build apk --debug
```

- Single test: `flutter test test/<path>_test.dart`.
- Integration tests (`integration_test/`) are NOT run in CI. They run on Linux desktop: `flutter test integration_test -d linux` (takes ~2 minutes, requires the `StubSoundService` stub registered in `pumpApp`).
- Environment: native Ubuntu (no WSL). Android emulators available: AVDs `Pixel_10_Pro` (x86_64, Android 16) and `Pixel_10_Pro_Fold`. adb: `~/Android/Sdk/platform-tools/adb`. Android SDK: `~/Android/Sdk` (platform 36). Note: local `flutter build apk` may fail with Gradle error `Could not determine the dependencies of task ':app:compileFlutterBuildDebug'. > Index: 1, Size: 1` — Flutter picks up Java 25 from Android Studio's bundled jbr, but Gradle 9.1 supports Java ≤ 24. Fix: point Gradle at JDK 17/21 (e.g. install `openjdk-21-jdk-headless` and set `JAVA_HOME`) or run the build in CI, which uses the runner's JDK 17/21.
- Stack: Flutter/Dart, `drift` ORM, `signals`/`signals_flutter`, `go_router`, `fl_chart`, `flutter_localizations` (template `lib/l10n/app_ru.arb`).

## Generated code (commit it, CI never regenerates)

- Drift: `lib/core/database/app_database.g.dart` via `dart run build_runner build`. After changing table schemas also regenerate the schema dump `drift_schemas/drift_schema_v1.json` (`dart run drift_dev schema dump ...`) — no migration test exists, the JSON is the versioned record.
- l10n: `app_localizations*.dart` generated from `app_ru.arb`; committed and excluded from the analyzer (`flutter gen-l10n`, or auto-run on build via `generate: true`).

## Workflow & conventions

- Repo language is Russian: PLAN.md, commit messages, UI strings. Write commit messages as `task/NN.NN: <краткое описание на русском> (#PR)`.
- **Before opening a pull request, ask the user whether to run the e2e tests** (`integration_test/app_flow_test.dart` via `flutter test integration_test -d linux`, ~2 min, not in CI). The user may opt out; never run them silently or skip the question.
- Each task = branch `task/<NN>-<slug>` from `main` → PR → green CI → squash merge, in dependency order.
- **Update task branches with `git merge`, NOT `git rebase`.** Rebase rewrites history and has in this repo repeatedly dropped `PLAN.md` rows, broken `dart format`/l10n sync, and left the branch out of sync with `origin/main` — all invisible until CI/e2e failed. `git merge origin/main` keeps the shared `main` story intact and makes PR review (`git diff origin/main..HEAD`) deterministic. Remember: your real diff vs `main` is only the few files you actually changed (`git diff --name-status origin/main..HEAD`), the rest that differ are rebase fallout and must be reconciled, not committed.
- **Before every commit, run the `plan-review` agent** to verify: (1) the task is recorded in `PLAN.md` with correct status `[x]` and completion date; (2) if a work plan was drafted for this task, it was written into `PLAN.md`. Block the commit if either check fails.
- **After composing a work plan for a task, always write it into `PLAN.md`** before implementation begins — plan must exist in the file before code changes start.
- Keep the `@DriftDatabase` annotation on the database class, NOT on a top-level `const` — drift_dev 2.34 fails to detect the DB otherwise.
- If `build_runner` reports stale/skipped outputs after a schema change, `rm -rf .dart_tool/build` and rebuild.
- **After finishing a task with new functionality, run the `android-tester` subagent to APPEND test cases to `TEST_PLAN.md`** (короткий прогон: только добавить сценарии для нового функционала по протоколу — TC-<NNN>, шаги, ожидание). **Не запускать полный прогон всех сценариев** — полный QA-прогон стартует только по требованию пользователя или обязательно перед публикацией релиза.
- **UI опирается на `lib/uikit/`** — единый источник базовых компонентов (`AppCard`, `AppSection`, `AppSectionHeader`, `AppGradientButton`, `AppStatCard`, `AppBadge`, `AppTile`, `AppThumbnail`, `AppEmptyState`). При создании нового или обновлении существующего UI отдавать приоритет компонентам uikit перед ручным дублированием: заголовки секций — `AppSectionHeader`/`AppSection` (не `Text(... titleMedium)`), primary CTA — `AppGradientButton`, карточки/списки — `AppCard`/`AppTile`. Контекстные виджеты — в `features/<feature>/ui/`. Исключения (delete-действия и т.п.) — осознанно, с пометкой в PR.

## Testing quirks

- Unit/widget tests mirror `lib/` under `test/`. DB-dependent tests construct `AppDatabase(executor: NativeDatabase.memory())`.
- Tests assert on `AppLocalizations` Russian strings (`app_ru.arb`).

## Как запустить тестировщика (`android-tester`)

- **Короткий прогон (append сценариев):** после задачи с новым функционалом — «запусти android-tester: добавь тест-кейсы для <фича>». Агент только допишет новые сценарии в `TEST_PLAN.md` (TC-<NNN>, шаги, ожидаемый результат), полный прогон НЕ выполняет.
- **Полный QA-прогон:** «запусти android-tester: проверь все экраны» (или конкретную область). Стартует только по требованию пользователя или обязательно перед публикацией релиза. Агент сам поднимет эмулятор, соберёт/установит debug-сборку, обойдёт экраны, придумает stress-сценарии и запишет каждый сценарий в `TEST_PLAN.md`.
- **Задачи на фикс:** после прогона каждый найденный дефект (`FAIL`/`BLOCKED`) агент заводит как новую задачу в `PLAN.md` (продолжая нумерацию, без `✅`) — краткое описание, причина, ссылка на TC. Код не чинит.
- Эмулятор: AVD `Pixel_10_Pro` (x86_64, Android 16). adb: `~/Android/Sdk/platform-tools/adb`. Учётная запись на эмуляторе — google_apis_playstore.
- Ручной запуск вне агента: см. `.agents/agents/android-tester.md` (окружение, команды UI-взаимодействия, протокол `TEST_PLAN.md`).
