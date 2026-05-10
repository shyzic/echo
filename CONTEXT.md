# Эхо Двух Миров — Context для ИИ-помощника

> Читай этот файл первым. Здесь всё, что нужно знать о проекте чтобы помогать без лишних вопросов.

---

## Стек и структура

- **Движок:** Godot 4.4, GDScript only, Forward+ renderer
- **Разрешение:** 480×270 внутреннее, 1920×1080 окно, integer scale 4×
- **Путь проекта:** `D:\Hackathon\GameJam\godot\game\echo\`
- **GitHub:** `https://github.com/shyzic/echo.git` (ветка `main`)
- **Тайл:** 32×32 px, карта 60×60 тайлов

---

## Жанр и суть игры

Атмосферный narrative-puzzle. Мальчик Аман ищет пропавшего отца в лесу с двумя реальностями — **Свет** (обычный мир) и **Эхо** (тёмный мир прошлого). Боёв нет. Конфликт внутренний. Финал — выбор между двумя горькими концовками.

**Управление:**
- `WASD` / стрелки — движение
- `E` — взаимодействие
- `Q` — переключить реальность (кулдаун 0.6s)
- `Пробел` — эхолокация ping (только в Эхо)
- `Escape` — пауза

---

## Нарративный поток (обязательный порядок)

```
TitleScreen → World
  HOME (старт игрока)
    ↓ исследование, письма, пазлы
  HUT (хижина отца, центр карты)
    → Поговорить с мамой (Npc)
    → Прочитать дневник отца (Diary) ← ОБЯЗАТЕЛЬНО для продолжения
    ↓ GameState.diary_read = true
  HEART (сердце леса, угол карты)
    → HeartShrine — только если diary_read = true
    → Диалог отца (7 реплик)
    → ChoiceUI → Концовка A или B
      → EndingScreen → TitleScreen
```

Без чтения дневника HeartShrine показывает: *"Сначала найди хижину отца"*.

---

## Автолоады (синглтоны, всегда доступны)

| Синглтон | Файл | Что делает |
|---|---|---|
| `GameState` | `scripts/globals/GameState.gd` | Флаги прогресса: `letters_collected`, `puzzle_states`, `diary_read`, `hut_visited`, `anchors_visited`, `play_time_seconds` |
| `SaveManager` | `scripts/globals/SaveManager.gd` | In-memory чекпоинт: `save_checkpoint(pos, reality)` / `restore()` → dict с pos/reality/letters/puzzles |
| `AudioManager` | `scripts/globals/AudioManager.gd` | Процедурные звуки (нет файлов). `play("shift"\|"ping"\|"pickup"\|"anchor"\|"death"\|"switch"\|"door")`, `play_ambient(reality_int)` |
| `RealityManager` | `scripts/globals/RealityManager.gd` | `current`: LIGHT=0/ECHO=1. `toggle()`, `is_echo()`, `can_toggle()`. Сигналы: `reality_changed(Reality)`. `FADE_TIME=0.4`, `COOLDOWN=0.6` |
| `DialogueManager` | `scripts/globals/DialogueManager.gd` | `start(key, callback?)` / `play_letter(key, callback?)` / `advance()`. Флаг `active: bool`. Данные из `data/dialogues.json` и `data/letters.json` |
| `SceneRouter` | `scripts/globals/SceneRouter.gd` | `goto_title()`, `goto_world()`, `goto_ending("free"\|"stay")` — все через `call_deferred` |

---

## Const.gd (class_name, НЕ автолоад)

```gdscript
TILE_SIZE = 32
MAP_W_TILES = MAP_H_TILES = 60
PLAYER_SPEED = 90.0
PING_RADIUS_MAX = 220.0
TINT_LIGHT = Color(1,1,1,1)
TINT_ECHO = Color(0.18, 0.22, 0.42, 1.0)
```

---

## Главные сцены

| Сцена | Путь | Описание |
|---|---|---|
| Main | `scenes/Main.tscn` | Точка входа, запускает `goto_title()` |
| TitleScreen | `scenes/ui/TitleScreen.tscn` | Главное меню |
| World | `scenes/world/World.tscn` | Игровой мир. Содержит: GroundTilemap, EntitiesContainer, Player, RealityFade, HUD, DialogueBox |
| Player | `scenes/entities/Player.tscn` | CharacterBody2D + AnimatedSprite2D (8 анимаций: walk/idle × down/up/left/right) |
| EndingScreen | `scenes/ui/EndingScreen.tscn` | Концовки (free / stay / free_all_letters) |
| PauseMenu | `scenes/ui/PauseMenu.tscn` | Escape-меню |
| DialogueBox | `scenes/ui/DialogueBox.tscn` | Typewriter 30 cps, skip по E/Пробел |
| HUD | `scenes/ui/HUD.tscn` | Реальность (top-left), письма (top-right), hint (bottom-center) |
| DeathOverlay | `scenes/effects/DeathOverlay.tscn` | Fade-to-black при смерти |
| ChoiceUI | `scenes/ui/ChoiceUI.tscn` | Финальный выбор: "Освободить отца" / "Занять место" |

---

## Сущности (entities)

### Игрок (`Player.gd`)
- `dead`, `input_locked`, `has_key: bool`
- `die()` → DeathOverlay fade → восстановление из SaveManager → fade back
- Hint через группу `"hud"`: `show_hint(text)` / `hide_hint()`
- При подходе к Area2D с `interact()` → показывает hint. При отходе — скрывает (deferred, 2 кадра)
- Пауза: `load("res://scenes/ui/PauseMenu.tscn").instantiate()` в root

### Интерактивные объекты (все Area2D)
| Объект | Файл | Что делает |
|---|---|---|
| `Letter` | `Letter.gd` | Читает письмо через `DialogueManager.play_letter()`, затем `collect_letter()` + `queue_free()` |
| `Anchor` | `Anchor.gd` | Сохраняет чекпоинт через SaveManager, пульсирует alpha, запускает `anchor_activated` диалог |
| `Key` | `Key.gd` | Устанавливает `player.has_key = true`, `queue_free()` |
| `Door` | `Door.gd` | StaticBody2D. `open()` если `player.has_key`. Иначе `door_locked` диалог |
| `Switch` | `Switch.gd` | Только в Эхо. Эмитирует `activated(self)`. Управляется `EchoSwitchGate` |
| `Npc` | `Npc.gd` | Мать у хижины. Устанавливает `hut_visited = true`. Запускает `mother_intro` |
| `Diary` | `Diary.gd` | Дневник отца. Устанавливает `diary_read = true`. **Ворота к финалу** |
| `HeartShrine` | `HeartShrine.gd` | Финальный объект. Требует `diary_read = true`. Запускает `father_climax` → ChoiceUI |
| `Chasm` | `Chasm.gd` | Area2D. Убивает в Свете, безопасен в Эхо (мост закрывает) |

### Статичные объекты (StaticBody2D)
| Объект | Описание |
|---|---|
| `Tree` | Блокирует путь, нет взаимодействия |
| `Stone` | То же |
| `Bridge` | Node2D, виден только в Эхо (визуально закрывает Chasm) |
| `Door` | StaticBody2D, блокирует пока не открыта ключом |

### Враги
| Объект | Файл | Описание |
|---|---|---|
| `Monster` | `Monster.gd` | CharacterBody2D. Активен только в Эхо. Chase radius 120px, speed 40. `HurtArea` → `player.die()`. Ищет игрока через группу `"player"` |

---

## Система реальностей

- **Свет (LIGHT):** белый CanvasModulate, PointLight2D выключен
- **Эхо (ECHO):** тёмно-синий CanvasModulate `Color(0.18,0.22,0.42)`, PointLight2D включён (энергия 1.0)
- Переключение: `RealityManager.toggle()` → tween цвета + light energy
- `RealityFade.tscn` — белый flash поверх при переключении
- Монстры, Chasm, Switch, Bridge — видны/активны только в одной реальности

---

## ProcGen (карта)

`ProcGen.generate(seed) → Dictionary`:
- `grid` — 60×60 массив тайлов (0=трава А, 1=трава Б, 2=тропа)
- `pois` — `{HOME, HUT, HEART}` Vector2i позиции
  - HOME: верхний-левый угол (~8,8)
  - HUT: центр карты (~30,30)
  - HEART: нижний-правый угол (~50,50)
- `entity_spawns` — Trees и Stones
- `puzzle_spawns` — 4 пазла: RealityBridgeGate, KeyLockGate×2, EchoSwitchesGate
- `letter_spawns` — 6 позиций для писем
- `anchor_spawns` — 3 позиции якорей
- `monster_spawns` — 3 монстра (только в глубине леса)

**Граница карты:** 2 ряда тёмных деревьев по периметру + 4 невидимых StaticBody2D стены снаружи.

---

## Пазлы

| Тип | Как работает |
|---|---|
| `RealityBridgeGate` | Chasm (убивает в Свете) + Bridge (виден в Эхо) на одном тайле. Нужно переключиться в Эхо чтобы пройти |
| `KeyLockGate` | Door (StaticBody2D) + Key (Area2D в 4 тайлах). Подобрать Key → `has_key=true` → Door.open() |
| `EchoSwitchesGate` | 2 Switch (Area2D, только Эхо) + Door. `EchoSwitchGate.gd` координирует: оба активированы → Door.open() |

---

## Данные

**`data/letters.json`** — 6 писем (letter_1..letter_6). Письма отца Сардора сыну Аману.

**`data/dialogues.json`** — ключевые диалоги:
- `mother_intro` — мать у хижины
- `father_diary` — 4 страницы дневника (читается у Diary объекта)
- `father_climax` — 7 реплик отца в финале
- `heart_locked` — блокировка HeartShrine без дневника
- `anchor_activated`, `key_pickup`, `door_locked` — системные

---

## Типичные ошибки / правила GDScript 4.4

1. `var x := [Vector2i.UP, ...]` — **ошибка**, массив не типизирован. Нужно: `var x: Array[Vector2i] = [...]`
2. `Facing.keys()[facing].to_lower()` возвращает Variant → нужно `var s: String = ...`
3. `change_scene_to_file()` из `_ready()` → всегда через `.call_deferred()`
4. PointLight2D с `energy=0` в Forward+ → серый экран. Решение: `visible=false` вместо energy=0
5. Все non-root ноды в `.tscn` ОБЯЗАТЕЛЬНО имеют `parent="."` или `parent="NodeName"`
6. Чтобы удалить Area2D и убрать хинт → `queue_free()` + `_refresh_hint_deferred()` (ждать 2 кадра)

---

## Спрайты

| Путь | Описание |
|---|---|
| `assets/sprites/player/Вниз/Frame1-4.png` | Анимация игрока вниз |
| `assets/sprites/player/Вверх/Frame1-4.png` | Анимация игрока вверх |
| `assets/sprites/player/На лево/Frame 1-4 .png` | Анимация игрока влево |
| `assets/sprites/player/На право/Frame 1-4.png` | Анимация игрока вправо |
| `assets/sprites/skeleton.png` | Спрайт монстра, 10 колонок × 6 строк |
| `assets/sprites/*_placeholder.png` | Плейсхолдеры для деревьев, камней, якорей и т.д. |
| `assets/tiles/placeholder.png` | Тайлсет 192×32: 6 тайлов по 32px |
| `assets/vfx/light_gradient.png` | Текстура PointLight2D игрока |

---

## Что НЕ реализовано (в планах или вырезано)

- Реальные аудио файлы (сейчас процедурная генерация beeps/drones в AudioManager)
- Анимации монстра (показывает только frame 0)
- NPC-мать без спрайта (visible=false)
- Puzzle 4 (Memory Stones) и Puzzle 5 (Sound Hollow) из GDD
- Скрытая концовка C
- Катсцены (letterbox, camera hijack)
- Журнал писем (Tab)
- Эффект heartbeat / vignette

---

## Как вносить правки

1. Все скрипты в `scripts/`, сцены в `scenes/`
2. После правок: `git add -A && git commit -m "..." && git push`
3. Remote: `https://github.com/shyzic/echo.git`
4. При ошибке типа в GDScript — чаще всего нужна явная аннотация типа `: String`, `: Vector2i` и т.д.
