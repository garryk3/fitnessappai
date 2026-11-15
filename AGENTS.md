# AGENTS.md — ядро правил FitnessAppAI

Краткие правила, нужные каждой сессии. Детали по ссылкам:
- `docs/AGENTS_DETAILS.md` — окружение (JDK/эмулятор/NDK), generated-код, вендор-плагин, протокол `TASKS.md`, запуск `android-tester`/`design-reviewer`, симлинки opencode.
- `docs/REPO_CONTEXT.md` — контекст репозитория для субагентов (читают целиком при старте).
- `docs/PROJECT.md` — стек и принятые решения. `DESIGN.md` — дизайн-система.

## Repo layout

- **Git repo root** (все `git`-операции, `PLAN.md`, `AGENTS.md`, `DESIGN.md`): `git rev-parse --show-toplevel`. Поддиректория корнем не является.
- **Flutter package** — подпапка `fitnessappai/` (`pubspec.yaml`, `lib/`, `test/`, `integration_test/`). Все `flutter`/`dart` команды — с `workdir: fitnessappai/` (CI: `working-directory: fitnessappai`). `git` команды работают из любого места под корнем; `../PLAN.md` относительно пакета — тот же файл.
- Трекеры (корень): `PLAN.md` (живой план), `PLAN_ARCHIVE.md` (архив этапов), `TASKS.md` (ящик пользователя), `TEST_PLAN.md` (накопительный тест-план, ведёт `android-tester`). Стабильный техконтекст — `docs/PROJECT.md`; контракт LLM-генерации — `docs/llm_contract.md`.
- `lib/uikit/` — единый источник базовых UI-компонентов (`AppCard`, `AppSection`, `AppSectionHeader`, `AppGradientButton`, `AppStatCard`, `AppBadge`, `AppTile`, `AppThumbnail`, `AppEmptyState` и др.).
- `.agents/`: `rules/FLUTTER.md` (стиль/state), `skills/<name>/SKILL.md` (скиллы), `agents/*.md` (субагенты). `rules/FLUTTER.md` соблюдать: native-first state (signals, `ChangeNotifier`, `ValueNotifier`), **без Riverpod/Bloc/GetX**, MVVM, manual DI.

## Как читать PLAN.md

**Не читать целиком** — найди секцию задачи (`grep -n -E '^### NN\.' PLAN.md`) и прочитай только её диапазон (`sed -n 'A,Bp' PLAN.md`). Статус задачи (`[x]` + дата) обновляется при завершении, **до открытия PR**. Рабочий план задачи записывается в `PLAN.md` **до начала кода**.

## Commands (CI in `.github/workflows/ci.yml` is the source of truth)

```sh
# workdir: fitnessappai/
flutter pub get
dart format --output=none --set-exit-if-changed lib test tool integration_test
flutter analyze --fatal-infos
dart analyze lib --fatal-infos   # гейт restrict_raw_flutter; таргет `lib` ОБЯЗАТЕЛЕН (Dart 3.14: плагин-диагностики отдаются только при каталоге-таргете, dart-lang/sdk#64208)
flutter test
flutter build apk --debug
```

- Single test: `flutter test test/<path>_test.dart`. e2e (`integration_test/`) в CI не прогоняются — локально `flutter test integration_test -d linux` (долго на холодном прогоне; подробности — детали).
- Stack: Flutter/Dart stable (без пина), `drift`, `signals`/`signals_flutter`, `go_router`, `fl_chart`, `flutter_localizations`, виджеты из `package:material_ui`. Окружение и подводные камни — `docs/AGENTS_DETAILS.md`.

## Workflow & conventions

- Язык репо — русский: `PLAN.md`, commit messages (`task/NN.NN: <описание> (#PR)`), UI-строки — только через `lib/l10n/app_ru.arb`.
- Задача = ветка `task/<NN>-<slug>` из `main` → PR → зелёный CI → squash merge, в порядке зависимостей. Перед коммитом/PR ветка синхронизируется с `origin/main` через **`git merge origin/main` (никогда не `rebase`)** — rebase/устаревшая ветка неоднократко роняли строки `PLAN.md` и ломали синхронизацию format/l10n. Реальный diff — только фактически изменённые файлы (`git diff --name-status origin/main..HEAD`).
- **Состояние задачи в `PLAN.md` — до открытия PR, а не после.**
- **Перед PR спросите пользователя, запускать ли e2e** (`flutter test integration_test -d linux`; 7+ мин на холодном прогоне, not in CI). Молча не запускать и не пропускать вопрос нельзя.
- **Перед публикацией релизного тега спросите владельца, нужен ли полный QA-прогон android-tester** (~час; иначе релиз на unit-тестах и CI). Отказ не блокирует релиз; молчать нельзя.
- **Гейты ревью (субагенты, `.agents/agents/`):**
  - После реализации, **перед коммитом/PR — `task-reviewer`** (вердикт `DO NOT SHIP` блокирует). Исключение: задачи без изменений кода (чистка `TASKS.md`, планы, рабочие планы) — этапы в индексе и планах достаточно самопроверки.
  - Задача с UI-изменениями в `lib/` — также **`design-reviewer`** (только diff-файлы; вердикт `REDESIGN REQUIRED` блокирует).
  - **Перед релизом — `plan-review`** (задачи с `[x]`+датой и рабочими планами в `PLAN.md`).
  - **После релиза `release-manager` сжимает `PLAN.md`** (завершённые этапы → `PLAN_ARCHIVE.md`, индекс и нумерация сохраняются).
  - После задачи с новым функционалом — **`android-tester` коротким прогоном** дополняет `TEST_PLAN.md` (только append сценариев). Полный QA — по требованию или перед релизом.
- **UI — только через `lib/uikit/`**: заголовки секций — `AppSectionHeader`/`AppSection` (не `Text(... titleMedium)`), primary CTA — `AppGradientButton`, карточки/списки — `AppCard`/`AppTile`. Контекстные виджеты — в `features/<feature>/ui/`. Исключения (delete-действия и т.п.) — осознанно, с пометкой в PR.
- **Сырые Material-виджеты запрещены вне `lib/uikit/`** (analyzer-плагин `restrict_raw_flutter` — вендорный форк, история в деталях): `Text`→`AppText`, `Scaffold`→`AppScaffold`, `AppBar`→`AppTopBar`, `Card`→`AppCard`, `ListView`/`GridView`→`AppListView`/`AppGridView`, `FilledButton`→`AppButton`, `AlertDialog`/`showDialog`→`AppDialog`/`showAppDialog`, `SnackBar`→`showAppSnackBar`, `Colors.*`/`Color(...)` вне `lib/app/theme` — запрещены. Гейты: `dart analyze lib --fatal-infos` (плагин), CI «Guard uikit exemptions» и «Guard raw interactive widgets» (grep word-boundary; полный список — в `.github/workflows/ci.yml`). Зоны исключения — `lib/uikit/**`, `lib/app/theme/**`, `test/**`, `integration_test/**` + generated-файлы.
- Generated-код коммитится (drift, l10n) — команды и тонкости: `docs/AGENTS_DETAILS.md`.
