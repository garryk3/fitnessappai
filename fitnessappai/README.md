# FitnessAppAI

Мобильное приложение для планирования и отслеживания спортивных тренировок.
Offline-first, Android 12+ (minSdk 31), Material 3 (тёмная тема), локализация — русский.

## Быстрый старт

```bash
cd fitnessappai
flutter pub get                 # установка зависимостей
flutter gen-l10n                # генерация локализации (app_localizations*.dart)
dart run build_runner build     # генерация кода drift (app_database.g.dart)
flutter run                     # запуск приложения
flutter test                    # тесты
flutter build apk --debug       # сборка Android APK
```

Генерируемые файлы (drift, локализация) закоммичены: при обычном запуске и
сборке они создаются автоматически (`generate: true`). Команды генерации нужны
только после изменения схемы БД или `app_ru.arb`.

## Возможности

- **Упражнения**: встроенная база (15+ упражнений из открытой БД wger, 3 типа —
  силовые/планка/бег) с анимированными WebP-подсказками, схемой мускулатуры
  (CustomPainter, ~15 групп мышц), поиском и фильтром по типу. Можно добавлять
  свои упражнения.
- **Программы**: конструктор на 1–7 дней с привязкой к дням недели, основной и
  альтернативный наборы упражнений, параметры подходов (повторы/вес/время/дистанция).
- **Выполнение тренировок**: фиксация подходов всех типов, таймер отдыха,
  удержание экрана (wake lock), экран итогов.
- **План недели**: статусы тренировочных дней (выполнено/перенесено/пропущено),
  перенос на сегодня, отметка пропуска, напоминания о тренировочных днях.
- **Прогресс**: статистика за неделю/месяц/год, графики (fl_chart), распределение
  нагрузки по мышцам, история тренировок с деталями по подходам.
- **Профиль**: замеры тела (рост, вес, 8 обхватов) с графиками, противопоказания
  с предупреждениями в UI.
- **Синхронизация**: ручной экспорт/импорт файла БД (интерфейс `SyncService`
  рассчитан на будущую облачную синхронизацию).
- **LLM (после MVP)**: интерфейс генерации упражнений + JSON-контракт
  (`docs/llm_contract.md`), заглушка вместо реальной модели.

## Стек

- Flutter / Dart, state management: `signals` + `signals_flutter`
- SQLite через `drift` (типобезопасный ORM)
- `go_router` (навигация), `fl_chart` (графики), `flutter_local_notifications`
  (напоминания), `wakelock_plus` (удержание экрана)
- CI: GitHub Actions (analyze, format, tests, сборка APK)

Полный план разработки с отслеживанием статусов — в [PLAN.md](../PLAN.md).

## Структура проекта

```
lib/
  main.dart
  app/                # app.dart, router.dart, theme/, responsive/
  core/
    database/         # app_database.dart, tables/, converters/, seed/
    di/               # service_locator.dart
    media/            # media_store.dart, media_cache.dart
    notifications/    # reminder_service.dart
    domain/models/    # domain-модели фич
    domain/validators/ # валидаторы
  features/
    exercises/        # data/ + ui/ (список, детали, форма, схема мышц)
    programs/         # data/ + ui/ (список, конструктор, параметры)
    workout/          # data/ + ui/ (план недели, подготовка, выполнение)
    progress/         # domain/ + ui/ (статистика, графики, история)
    profile/          # data/ + ui/ (профиль, замеры, противопоказания)
    llm/              # domain/ (контракт генерации контента)
    sync/             # data/ + ui/ (экспорт/импорт БД)
  l10n/               # app_ru.arb, gen_l10n
assets/
  data/exercises_seed.json
  exercises/          # *.webp (анимации)
tool/                 # export_wger.dart
integration_test/
```

## Запуск

```bash
cd fitnessappai
flutter pub get
flutter run
```

## Проверки

```bash
flutter analyze --fatal-infos
dart format --output=none --set-exit-if-changed lib test tool integration_test
flutter test
flutter build apk --debug
```

## Seed-данные

Справочники (мышечные группы, теги противопоказаний) сидятся при создании БД
(`ReferenceSeeder`). Упражнения загружаются один раз из
`assets/data/exercises_seed.json` (`ExerciseSeeder`): анимации копируются в
storage через `MediaStore`, флаг `exercises_seeded` в `app_meta` защищает от
повторного сида.

> **Примечание.** Файлы `assets/exercises/*.webp` — временные статичные
> плейсхолдеры (сгенерированы локально), т.к. лицензионно чистые анимированные
> webp пока не подобраны. Замена на реальные анимации не требует изменений
> кода: достаточно заменить файлы с теми же именами и переустановить приложение.
> Инструмент для первичной загрузки данных из wger API — `tool/export_wger.dart`.

## Git-процесс

Каждая задача из PLAN.md выполняется в отдельной ветке `task/<NN>-<slug>`,
открывается Pull Request в `main`. Проверки (analyze + format + tests + сборка APK)
выполняет GitHub Actions (`.github/workflows/ci.yml`) на каждом PR и пуше в `main`.
