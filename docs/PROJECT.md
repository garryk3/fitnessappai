# PROJECT.md — стабильный технический контекст FitnessAppAI

> Вынесено из `PLAN.md` (разделы 0–8). Изменяется редко.
> Процесс разработки, команды и CI — авторитетны в `AGENTS.md`.

## 0. Решения по проекту

| Вопрос | Решение |
|---|---|
| Интеграция LLM | Отложена после MVP; в MVP — только интерфейс генерации (задача 6.1) |
| GGUF-модель | Определяется на Этапе 6 (кандидат — Qwen2.5 1.5B/3B) |
| Начальная база упражнений | Экспорт из открытой БД **wger** + адаптация на русский в JSON-ассет |
| Анимации упражнений | **Animated WebP**, хранение **файлами** в app storage (путь в БД) |
| Источник анимаций в MVP | Бандл-ассеты для стартовой базы + добавление вручную для кастомных |
| Схема мускулатуры | **CustomPainter**: ~15 групп мышц, вид спереди/сзади, Path-регионы |
| Расписание | **Жёсткое**: день недели закреплён за тренировочным днём; статусы выполнение/перенос/пропуск |
| Бег | Ручной ввод дистанции и времени, GPS не используется |
| Прерванная тренировка | Отбрасывается (не сохраняется) |
| Противопоказания | Теги на упражнении + профиль пользователя (предупреждения, решение за пользователем) |
| Метрики тела | Рост, вес + 8 обхватов (шея, грудь, талия, бёдра, бицепс, предплечье, бедро, икра), всё опционально |
| Напоминания | По тренировочным дням: своё время на день, задаётся пользователем, можно отключить |
| Синхронизация | MVP: ручной экспорт/импорт файла БД; интерфейс `SyncService` для будущего облака |
| CI | `dart format --set-exit-if-changed` + `flutter analyze --fatal-infos` + `dart analyze --fatal-infos` (правила `restrict_raw_flutter`) + `flutter test` + `flutter build apk --debug` |
| Название / applicationId | FitnessAppAI / `com.example.fitnessappai`; `minSdk = 31` |

## 1. Окружение и блокеры (снимок на старте проекта, 2026-02; актуальное — в AGENTS.md)

- **URL GitHub-remote не передан.** Без него невозможны PR в main — согласовать или создать через `gh repo create` перед задачей 0.1.
- Flutter 3.44.8 / Dart 3.12.2 установлены. Окружение — WSL2, Android SDK на Windows-диске. AVD для Android 12+ ещё не создан (нужен для интеграционных тестов и проверки адаптива).
- **Историческая правка (2026-09-25):** на текущую дату проект работает в нативном Ubuntu (без WSL2), `/dev/kvm` и AVD-ы `Pixel_10_Pro`/`Pixel_10_Pro_Fold` доступны, emulator-прогоны выполняются (см. 38.1, 45.9, AGENTS.md).
- **Поправка (2026-09-30, задача 47.18):** AVD `Pixel_10_Pro_Fold` на машине **отсутствует** — в `~/.android/avd` есть только `Pixel_10_Pro` (проверено `emulator -list-avds`). Упоминания Fold-AVD убраны из `AGENTS.md` и `TEST_PLAN.md`; в этом историческом снимке и в записях этапов 38.1/40.6 запись оставлена как есть, чтобы не переписывать журнал (в 38.1 добавлен маркер даты). Широкий форм-фактор задаётся на единственном AVD командой `adb shell wm size 3000x2800` (1000 dp; по умолчанию 1280×2856 @ 480dpi = 427 dp, то есть compact). Упоминания Samsung Fold 7 — реальное устройство, не AVD, оставлены.
- **Актуализация версии тулчейна (2026-09-30, задача 47.18):** Flutter **3.47.4** / Dart **3.13.3** (`flutter --version`), а не 3.44.8/3.12.2 из снимка на старте. Именно устаревшая строка выше породила неверную диагностику NDK в 47.18.
- Все flutter-команды выполняются с `workdir: fitnessappai/`.
- Сгенерированные Drift-файлы (`*.g.dart`) коммитятся в репозиторий (CI их не перегенерирует).

## 2. Git-процесс

Авторитетно в `AGENTS.md` (раздел `## Workflow & conventions`). Кратко: каждая задача — ветка `task/NN.NN-<slug>` от `main` → PR → зелёный CI → squash merge; ветку актуализируют через `git merge`, не `rebase`.

## 3. CI workflow

Авторитетно в `.github/workflows/ci.yml`. Один job `validate`: `dart format --set-exit-if-changed` → `flutter analyze --fatal-infos` → `dart analyze --fatal-infos` → `flutter test` → `flutter build apk --debug`.

`dart analyze --fatal-infos` добавлен этапом 52 как гарантированный гейт: **`flutter analyze` диагностику analyzer-плагинов видит не на всех версиях** (Flutter 3.47.4 — не видит, 3.47.7 в CI — видит), поэтому оба шага оставлены. Запрет сырых Material-виджетов (пакет `restrict_raw_flutter`, конфигурация — в `fitnessappai/analysis_options.yaml`) проверяется только анализатором. **Путь аргументом передавать нельзя** — `dart analyze lib` плагин не грузит (проверено 2026-10-12: 0 диагностик вместо 703), а `exclude_for_plugin`/`--options` у `dart analyze` нет, поэтому гейт идёт по всему пакету, и сырые виджеты разрешены в `lib/uikit/**`, `lib/app/theme/**`, `test/**`, `integration_test/**` — там `// ignore_for_file: type=lint` (у плагина нет исключения по путям). В остальном `lib/` такое подавление запрещено отдельным CI-шагом «Guard uikit exemptions».

## 4. Стек пакетов

- **Runtime:** `drift`, `drift_flutter`, `signals`, `signals_flutter`, `go_router`, `fl_chart`, `intl`, `uuid`, `collection`, `path_provider`, `path`, `wakelock_plus`, `flutter_local_notifications`, `timezone`, `file_picker`, `share_plus`.
- **Dev:** `drift_dev`, `build_runner`, `flutter_lints`, `mocktail`, `fake_async`, `integration_test` (SDK). (`restrict_raw_flutter` — analyzer-плагин этапа 52; объявлен только в `analysis_options.yaml`, в `pubspec.yaml` его нет.)
- Анимированный WebP рендерится нативным кодеком Flutter (без пакетов). Схема мышц — CustomPainter (без пакетов).
- `flutter_signals` на pub.dev — нерабочая заглушка; используем `signals` + `signals_flutter` (v7.x).

## 5. Структура проекта

```
fitnessappai/
  lib/
    main.dart
    app/                # app.dart, router.dart, theme/, responsive/
    uikit/              # UI-кит: единые компоненты интерфейса (AppText, AppCard,
                        # AppButton, AppScaffold, …) — основной слой, где
                        # разрешены сырые Material-виджеты (этап 52)
                        # (плюс токены lib/app/theme/**)
    core/
      database/         # app_database.dart, tables/, converters/
      di/               # service_locator.dart
      l10n/             # app_ru.arb, gen_l10n
      media/            # media_store.dart, media_cache.dart
      utils/
    features/
      exercises/        # data/ domain/ ui/
      programs/         # data/ domain/ ui/
      workout/          # data/ domain/ ui/
      progress/         # data/ domain/ ui/
      profile/          # data/ domain/ ui/
      llm/              # domain/ (интерфейс + DTO + парсер)
      sync/             # domain/ + ui/
  assets/
    data/exercises_seed.json
    exercises/          # *.webp (анимации)
  tool/                 # export_wger.dart
  integration_test/
```

## 6. Схема БД (Drift)

- `app_meta` — key/value: версия данных, флаг `seeded`.
- `muscle_groups` — id, key, labelRu, view (front/back), regionKey (для Path-региона диаграммы). Справочник ~15 групп.
- `contraindication_tags` — id, key, labelRu; `exercise_contraindications` — M2M.
- `user_profiles` — одна строка (id=1); `user_contraindications` — M2M.
- `exercises` — id, name, description, instructions, commonMistakes (JSON-список), type TEXT (strength/plank/running), thumbnailPath, animationPath, isCustom, createdAt, updatedAt.
- `exercise_muscles` — exerciseId, muscleGroupId, intensity TEXT (primary/secondary).
- `programs` — id, name, description, daysCount, createdAt, updatedAt.
- `program_days` — id, programId (CASCADE), dayIndex (0–6), dayOfWeek (1=Пн…7=Вс, nullable).
- `program_day_exercises` — id, dayId (CASCADE), exerciseId (SET NULL), orderIndex, sets, reps, durationSeconds, weightKg, distanceMeters, restSeconds, isAlternative BOOL.
- `workout_reminders` — id, programDayId (CASCADE), hour, minute, enabled.
- `workout_sessions` — id, programId (SET NULL), programName (копия), programDayId (SET NULL), dayIndex (копия), variant TEXT (main/alternative), performedDate, startedAt, endedAt, status.
- `workout_set_results` — id, sessionId (CASCADE), exerciseId (SET NULL), exerciseName/exerciseType (копии), setIndex, reps, weightKg, durationSeconds, distanceMeters, completedAt.
- `schedule_marks` — id, programDayId, weekStart, status TEXT (skipped).
- `body_measurements` — id, date, heightCm, weightKg, neckCm, chestCm, waistCm, hipsCm, bicepsCm, forearmCm, thighCm, calfCm (кроме date — все nullable).

**Статусы недели (вычисляемые):** `performed` (сессия на неделе), `rescheduled` (сессия есть, но дата ≠ закреплённый день), `skipped` (отметка в `schedule_marks`), иначе `pending`.

**Метрики по типам:** strength → sets+reps+weightKg; plank → sets+durationSeconds; running → distanceMeters+durationSeconds.

## 7. Каталог мышц (15 групп)

пресс, косые, грудь, плечи, бицепс, трицепс, предплечья, трапеции, широчайшие, поясница, ягодицы, квадрицепсы, бицепс бедра, икры, шея.

## 8. Пример seed-данных

```json
{
  "version": 2,
  "exercises": [
    {
      "name": "Приседания с гирей",
      "type": "strength",
      "description": "Гирю держать обеими руками на груди, присесть до параллели, встать, сохраняя спину прямой.",
      "instructions": "1. Ноги на ширине плеч, носки чуть врозь. 2. Опускайтесь, отводя таз назад. 3. В нижней точке колени не уходят внутрь.",
      "commonMistakes": ["Кругление поясницы", "Колени уходят внутрь", "Отрыв пяток"],
      "muscles": { "primary": ["квадрицепсы", "ягодицы"], "secondary": ["пресс"] },
      "contraindications": ["колени", "спина"],
      "animation": "goblet_squat.webp",
      "source": "wger"
    }
  ]
}
```

Стартовый набор (мин. 15): силовые — «Приседания с гирей», «Рывок гири», «Махи гирей», «Жим гири над головой», «Подтягивания на турнике», «Отжимания на брусьях», «Отжимания от пола», «Становая тяга с гирей»; планка — «Планка на локтях», «Боковая планка», «Планка с подъёмом ноги»; бег — «Бег на выносливость», «Бег на дистанцию», «Интервальный бег».

---
