# AGENTS.md

## Repo layout

- Git repo root hosts the Flutter app in `fitnessappai/`. All `flutter`/`dart` commands must run with `workdir: fitnessappai/` (CI sets `working-directory: fitnessappai`).
- `PLAN.md` (root): task tracking with `[x]` statuses + progress table. Update it whenever a task is done. Russian language.
- `docs/llm_contract.md`: contract for the LLM content-generation interface (future tasks 6.2–6.6).
- Flutter style/state-mgmt rules live in `.agents/rules/FLUTTER.md` (loaded via `opencode.json` `instructions`). Follow it: native-first state (signals, `ChangeNotifier`, `ValueNotifier`), no Riverpod/Bloc/GetX, MVVM, manual DI.

## Commands (CI in `.github/workflows/ci.yml` is the source of truth)

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test tool integration_test
flutter analyze --fatal-infos
flutter test
flutter build apk --debug
```

- Single test: `flutter test test/<path>_test.dart`.
- Integration tests (`integration_test/`) are NOT run in CI and need an Android emulator — none exists in this WSL2 env (Android SDK on Windows disk, no AVD). Don't attempt to run them locally.
- Stack: Flutter/Dart, `drift` ORM, `signals`/`signals_flutter`, `go_router`, `fl_chart`, `flutter_localizations` (template `lib/l10n/app_ru.arb`).

## Generated code (commit it, CI never regenerates)

- Drift: `lib/core/database/app_database.g.dart` via `dart run build_runner build`. After changing table schemas also regenerate the schema dump `drift_schemas/drift_schema_v1.json` (`dart run drift_dev schema dump ...`) — no migration test exists, the JSON is the versioned record.
- l10n: `app_localizations*.dart` generated from `app_ru.arb`; committed and excluded from the analyzer (`flutter gen-l10n`, or auto-run on build via `generate: true`).

## Workflow & conventions

- Repo language is Russian: PLAN.md, commit messages, UI strings. Write commit messages as `task/NN.NN: <краткое описание на русском> (#PR)`.
- Each task = branch `task/<NN>-<slug>` from `main` → PR → green CI → squash merge, in dependency order.
- Keep the `@DriftDatabase` annotation on the database class, NOT on a top-level `const` — drift_dev 2.34 fails to detect the DB otherwise.
- If `build_runner` reports stale/skipped outputs after a schema change, `rm -rf .dart_tool/build` and rebuild.

## Testing quirks

- Unit/widget tests mirror `lib/` under `test/`. DB-dependent tests construct `AppDatabase(executor: NativeDatabase.memory())`.
- Tests assert on `AppLocalizations` Russian strings (`app_ru.arb`).
