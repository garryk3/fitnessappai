# FitnessAppAI

Мобильное приложение для планирования и отслеживания спортивных тренировок.
Offline-first, Android 12+ (minSdk 31), Material 3 (тёмная тема), локализация — русский.

## Стек

- Flutter / Dart (state management: `signals` + `signals_flutter`)
- SQLite через `drift` (типобезопасный ORM)
- `go_router` (навигация), `fl_chart` (графики)

Полный план разработки с отслеживанием статусов — в [PLAN.md](../PLAN.md).

## Запуск

```bash
cd fitnessappai
flutter pub get
flutter run
```

## Проверки

```bash
flutter analyze --fatal-infos
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
