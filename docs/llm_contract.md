# LLM-контракт генерации контента упражнений

Документ фиксирует интерфейс между генератором контента и парсером
(`SuggestionJsonParser`). Используется для задач 6.2–6.6: выбор модели,
промпт-инжиниринг и реальная реализация `ExerciseContentGenerator`.

## 1. Вход генератора

Генератор принимает подсказку-название упражнения:

```
generate(nameHint) → ExerciseSuggestion
```

`nameHint` — краткое название или описание того, что нужно сгенерировать
(например, «приседания со штангой на плечах», «планка с упором на предплечья»).

## 2. Промпт (шаблон, русский язык)

> Ты — тренер по фитнесу. Сгенерируй описание упражнения по подсказке
> «{nameHint}».
>
> Ответь строго одним JSON-объектом по схеме ниже. Не добавляй текст вне JSON,
> не используй markdown-блоки. Все строки — на русском языке. Ключи
> `muscles` и `contraindications` заполняй ключами из справочников приложения.
>
> ```json
> {
>   "name": "Название упражнения",
>   "description": "1–2 предложения о назначении упражнения",
>   "type": "strength | plank | running",
>   "instructions": "Пошаговая техника выполнения (2–6 пунктов, каждый с новой строки)",
>   "commonMistakes": ["Типичная ошибка 1", "Типичная ошибка 2"],
>   "muscles": ["key_muscle_group", "key_muscle_group"],
>   "contraindications": ["key_contraindication", "key_contraindication"]
> }
> ```

## 3. Схема ответа (строгий JSON)

Ответ — один объект JSON. Поля:

| Поле | Тип | Обязательно | Правила валидности |
|---|---|---|---|
| `name` | string | да | непустая строка (после trim) |
| `description` | string | да | может быть пустой |
| `type` | string | да | одно из: `strength`, `plank`, `running` |
| `instructions` | string | да | может быть пустой |
| `commonMistakes` | array<string> | да | все элементы — строки |
| `muscles` | array<string> | да | все элементы — строки; ключи справочника мышечных групп |
| `contraindications` | array<string> | да | все элементы — строки; ключи справочника противопоказаний |

Допустимые ключи `muscles` берутся из таблицы `muscle_groups`
(например: `quads`, `chest`, `back`, `shoulders`, `core`, `glutes`, `hamstrings`).

Допустимые ключи `contraindications` берутся из таблицы
`contraindication_tags` (например: `knees`, `back`, `shoulders`,
`wrist`, `neck`, `hernia`, `pregnancy`).

Лишние поля объекта игнорируются парсером и не являются ошибкой.

## 4. Правила валидности

JSON считается валидным, если:

1. Ответ декодируется как JSON.
2. Корень — объект (`{}`), а не массив, строка или число.
3. Все обязательные поля присутствуют и имеют корректный тип (см. схему).
4. `name` непустой после обрезки пробелов.
5. `type` — одно из допустимых значений перечисления.

## 5. Ошибки

Любое нарушение правил из раздела 4 приводит к `MalformedSuggestionException`
с человекочитаемым сообщением, указывающим на проблемное поле. Парсер никогда
не «чинит» невалидный ответ и не возвращает частично разобранный объект —
это гарантирует, что сгенерированный контент не попадёт в базу с ошибками.

Примеры:

| Ответ модели | Результат |
|---|---|
| `{"name":"Жим","type":"strength","description":"","instructions":"","commonMistakes":[],"muscles":["chest"],"contraindications":[]}` | успех |
| `{"name":"","type":"strength",...}` | `MalformedSuggestionException: "name" не может быть пустым` |
| `{"name":"Жим","type":"yoga",...}` | `MalformedSuggestionException: Неизвестный "type": yoga` |
| `{"name":42,...}` | `MalformedSuggestionException: "name" должен быть строкой` |
| не-JSON текст | `MalformedSuggestionException: Ответ не является корректным JSON` |

## 6. Жизненный цикл

- **Задача 6.1 (текущая):** абстрактный `ExerciseContentGenerator`, DTO
  `ExerciseSuggestion`, парсер, заглушка `UnsupportedGenerator` в DI.
- **Задача 6.4:** `ExerciseContentGeneratorImpl` с реальной моделью —
  промпт из раздела 2, вывод передаётся в `SuggestionJsonParser`.
