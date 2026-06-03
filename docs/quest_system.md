# Quest System

Adapted from Sluggerpunk Survivors. Four parts plus save/event plumbing. Quest
**definitions** are static and never saved; only per-player **progress** persists,
so quests can be added or edited without breaking existing saves.

## Components

| File | Autoload | Role |
|------|----------|------|
| `core/quest_system/quest_database.gd` | `QuestDatabase` | Static `QUESTS` dict + `CATEGORY_ORDER`. Pure data. |
| `core/quest_system/quest_manager.gd` | `QuestManager` | Tracks progress, grants rewards, opens the log. |
| `core/quest_system/quest_text_parser.gd` | `QuestTextParser` | Wraps card/item names in quest text with BBCode links. |
| `ui/quest_log/quest_log.{gd,tscn}` | — | Procedural quest-card UI, three tabs. |

Autoload order matters: `QuestManager` is registered **after** `QuestDatabase`,
`QuestTextParser`, `SaveSystem`, `GameEvents`, and `SceneLoader` in `project.godot`.

## Save data

Two fields on `PlayerData` (`core/save_system/player_data.gd`):

```gdscript
@export var quest_progress: Dictionary = {}   # { quest_id: { progress, completed, claimed } }
@export var kills_by_type: Dictionary = {}     # { enemy_id: count }
```

Both are threaded through all four serialization points in `save_system.gd`
(`json_save`, `make_empty_save`, `check_missing_keys`, `json_load`) under a top-level
`"quests"` block. **If you add another PlayerData field, you must update all four** —
`check_missing_keys` is what migrates old saves (it logs "… not in Save File. Adding it now.").

> JSON loads numbers as floats. `QuestManager` `int()`s every count/progress read.

## Quest definition

Each entry in `QuestDatabase.QUESTS`:

```gdscript
"q_first_blood": {
    "title":        "First Blood",
    "description":  "Defeat your first enemy.",   # card/item names get highlighted
    "category":     "challenge",                  # "main" | "side" | "challenge"
    "type":         "total_kills",                # see types below
    "field":        "",                           # type-dependent (omit if unused)
    "target":       1,
    "reward_coins": 20,                           # granted via CurrencySystem on claim
    "reward_card":  "",                           # optional res:// Card path, "" = none
    "requires":     [],                           # prereq quest ids; hidden until all completed
}
```

There is no `reward_chips` (Sluggerpunk had two currencies; Oddside has coins only).

### Quest types

| type | progress computed from |
|------|------------------------|
| `player_data_bool` | bool field on `PlayerData` named by `field` (e.g. `level_one_completed`) → 0/1 |
| `enemy_kills` | `PlayerData.kills_by_type[field]` for one enemy id |
| `total_kills` | sum of all `kills_by_type` values |
| `enemy_types_met` | count of distinct enemy ids with ≥1 kill |
| `all_slots_equipped` | non-null slots in `PlayerData.equipped_cards` (max 6) |
| `currency` | `PlayerData.currency` |
| `event` | accumulated by signal handlers, stored in the entry's `progress` |

Derived types are recomputed on demand from `PlayerData`. `event` quests are advanced
by `_bump_event()` from signal handlers; the mapping lives in `EVENT_QUEST_HOOKS`.

## Public API (`QuestManager`)

```gdscript
get_progress(quest_id) -> { "progress": int, "completed": bool, "claimed": bool }
check_all()                # recompute every derived quest, emit updates — call on hub entry
claim_reward(quest_id)     # grant coins/card, mark claimed; returns true on success
is_unlocked(quest_id)      # true if all "requires" prerequisites are completed
toggle_log()               # open/close the quest log UI

signal quest_updated(quest_id)    # progress or claim state changed
signal quest_completed(quest_id)  # just reached target
```

`check_all()` runs automatically on load (`call_deferred`) and on `SceneLoader.scene_loaded`.

## Event plumbing

New `GameEvents` signals drive tracking:

- `enemy_killed(enemy_id)` — emitted from `Enemy.apply_damage()` on death.
  `enemy_id` is the exported `Enemy.enemy_id`, else the scene filename
  (e.g. `frog_enemy`), else the node name. Set `enemy_id` per enemy scene for
  stable type ids. **Bosses extend `BossEnemy` (not `Enemy`) and do not emit this**
  yet — add an emit in the boss death path if you want bosses to count.
- `card_equipped(card, slot)` — emitted from `CardSystem.set_slot_to_item()`.
  Drives `q_first_equip` (event) and refreshes `all_slots_equipped`.

## Opening the log

`QuestManager` listens for the `open_quest_log` input action (J / gamepad Y) in
`_unhandled_input` and toggles the log under its own `CanvasLayer`. No per-scene
setup needed — it works from anywhere, like the deck viewer.

## Text parser

`QuestTextParser.parse(text)` wraps known names (see `CARD_KEYWORDS`) in
`[url=card:<id>][color]…[/color][/url]`. The quest log connects `meta_clicked` to
`_on_keyword_clicked`, which currently just logs. **TODO:** point that handler at a
card detail popup / the deck viewer — it's one handler away.

## Adding a quest

1. Add an entry to `QuestDatabase.QUESTS` with a unique id.
2. Pick a `type`. For a new `event` quest, also add the quest id to
   `EVENT_QUEST_HOOKS` under the signal that should advance it, and ensure that
   signal is connected in `QuestManager._ready()`.
3. That's it — the UI builds from the database; no scene edits.

## Known limitations / TODOs

- Keyword click handler is a stub (`quest_log.gd:_on_keyword_clicked`).
- No mid-run completion toast — wire `QuestManager.quest_completed` to a popup.
- Bosses don't emit `enemy_killed` (see above).
- `CARD_KEYWORDS` is hand-maintained; there's no central card registry to derive it from.
