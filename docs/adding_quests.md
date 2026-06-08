---
title: Adding Quests in Oddside
description: A practical guide to authoring new quests — from a one-line definition to reward chains, kill challenges, and event-driven goals.
---

# Adding Quests

Oddside's quest system is **data-driven**: you describe a quest as a few lines in one
file, and the game does the rest — tracking progress, showing it in the quest log,
and handing out rewards. No scene editing, no per-quest UI work.

This guide walks through everything from the simplest possible quest to multi-step
chains and custom event goals.

---

## The 30-second version

Every quest lives in one dictionary inside **`core/quest_system/quest_database.gd`**.
To add a quest, add an entry:

```gdscript
"q_clear_forest": {
    "title":        "Out of the Woods",
    "description":  "Clear the forest level.",
    "category":     "main",
    "type":         "player_data_bool",
    "field":        "level_one_completed",
    "target":       1,
    "reward_coins": 100,
    "requires":     [],
},
```

Save the file and run the game. Open the quest log with **J** (or the **Y** button on
a gamepad) and your quest is there, tracking automatically. That's it.

---

## Anatomy of a quest

Each quest is a key (its **id**) mapped to a dictionary of fields.

| Field | Required | What it does |
|-------|:--------:|--------------|
| *the key* | ✅ | The quest **id**, e.g. `"q_clear_forest"`. Must be unique. Used everywhere to reference the quest. By convention it starts with `q_`. |
| `title` | ✅ | The name shown in the quest log. |
| `description` | ✅ | The body text. Card/item names are automatically highlighted (see [Highlighting names](#highlighting-card-names)). |
| `category` | ✅ | Which tab it appears under: `"main"`, `"side"`, or `"challenge"`. |
| `type` | ✅ | How progress is measured. See [Quest types](#quest-types). |
| `target` | ✅ | The amount needed to complete the quest. |
| `field` | sometimes | Names the data the quest reads. Required for `player_data_bool` and `enemy_kills`; ignored by the others. |
| `reward_coins` | ✅ | Coins granted when the player claims the quest. Use `0` for none. |
| `reward_card` | optional | A `res://` path to a card resource to grant on claim. Omit or `""` for none. |
| `requires` | ✅ | A list of quest ids that must be completed before this one appears. Use `[]` for "always available". |

> **Tip:** Keep ids stable once a quest ships. Players' progress is stored *by id*, so
> renaming an id orphans existing progress.

---

## Quest types

The `type` field decides how the game computes progress. Pick the one that matches
what you want the player to do.

| `type` | Measures | Needs `field`? | Example use |
|--------|----------|:--------------:|-------------|
| `player_data_bool` | A yes/no flag on the player's save (0 or 1) | ✅ | "Finish the tutorial", "Clear level two" |
| `enemy_kills` | Kills of **one specific** enemy type | ✅ | "Defeat 10 frogs" |
| `total_kills` | Every enemy killed, all types combined | — | "Defeat 25 enemies" |
| `enemy_types_met` | How many **different** enemy types you've killed | — | "Defeat 4 different kinds of enemy" |
| `all_slots_equipped` | How many of the six dice faces have a card | — | "Equip all six faces" |
| `currency` | The player's current coin total | — | "Save up 500 coins" |
| `event` | A custom counter you advance from code | — | "Equip your first card", "Open a chest" |

### `player_data_bool`

Reads a boolean field from the player's save. `field` is the name of that field.

```gdscript
"q_tutorial": {
    "title":        "First Roll",
    "description":  "Finish the tutorial and learn to roll.",
    "category":     "main",
    "type":         "player_data_bool",
    "field":        "tutorial_completed",
    "target":       1,
    "reward_coins": 50,
    "requires":     [],
},
```

Common flags you can read: `tutorial_completed`, `level_one_completed` …
`level_five_completed`, `demo_completed`. (These live on the player save in
`core/save_system/player_data.gd` — any `bool` there works.)

### Kill quests

```gdscript
# A specific enemy:
"q_frog_hunter": {
    "title": "Frog Hunter", "description": "Defeat 10 frogs.",
    "category": "challenge", "type": "enemy_kills",
    "field": "frog_enemy", "target": 10,
    "reward_coins": 80, "requires": [],
},

# Any enemies, total:
"q_slayer": {
    "title": "Slayer", "description": "Defeat 25 enemies.",
    "category": "challenge", "type": "total_kills",
    "target": 25, "reward_coins": 200, "requires": ["q_first_blood"],
},

# Variety:
"q_bestiary": {
    "title": "Know Thy Enemy", "description": "Defeat four different enemy types.",
    "category": "challenge", "type": "enemy_types_met",
    "target": 4, "reward_coins": 100, "requires": [],
},
```

**What's an enemy's `field` value?** It's the enemy's **id**. By default that's the
enemy scene's filename — e.g. an enemy at `…/frog/frog_enemy.tscn` has the id
`frog_enemy`. To use a custom id, set the `enemy_id` property on the enemy in the
editor; kill tracking will use that instead.

### `currency`

```gdscript
"q_saver": {
    "title": "Pocket Change", "description": "Save up 500 coins.",
    "category": "side", "type": "currency",
    "target": 500, "reward_coins": 50, "requires": [],
},
```

### `all_slots_equipped`

```gdscript
"q_full_loadout": {
    "title": "Fully Loaded", "description": "Equip a card to all six dice faces.",
    "category": "side", "type": "all_slots_equipped",
    "target": 6, "reward_coins": 150, "requires": ["q_first_equip"],
},
```

---

## Rewards

When a player **claims** a completed quest, they receive:

- **Coins** — `reward_coins`. Added through the in-game currency system, so the HUD
  updates and the save is written.
- **A card** *(optional)* — `reward_card`, a path to a card resource. For example:

```gdscript
"reward_card": "res://card/card_abilities/grenade.tres",
```

The card goes to an empty dice face if one is free, otherwise into the deck.

> Oddside uses a single currency (coins). There is no separate "chips" reward.

---

## Prerequisite chains

Use `requires` to gate quests behind others. A quest stays **hidden** in the log until
every quest in its `requires` list is completed.

```gdscript
"q_tutorial":  { …, "requires": [] },                 # always visible
"q_level_one": { …, "requires": ["q_tutorial"] },     # appears after tutorial
"q_level_two": { …, "requires": ["q_level_one"] },    # appears after level one
```

This is how you build a visible main-quest progression — each step reveals the next.

---

## Event quests (custom goals)

Most quest types read existing data. An **event** quest is one *you* advance from code
when something special happens ("the player equipped a card", "opened a chest", "talked
to a character"). It takes one extra wiring step.

**1. Define it** with `type: "event"`:

```gdscript
"q_first_equip": {
    "title": "Loadout", "description": "Equip a card to one of your dice faces.",
    "category": "side", "type": "event",
    "target": 1, "reward_coins": 30, "requires": [],
},
```

**2. Tell the quest manager which signal advances it.** Open
`core/quest_system/quest_manager.gd` and add your quest id under the relevant signal
in `EVENT_QUEST_HOOKS`:

```gdscript
const EVENT_QUEST_HOOKS := {
    "card_equipped": ["q_first_equip"],   # ← advances by 1 each time a card is equipped
}
```

The signal must be one the quest manager listens to (it connects to them in `_ready()`).
The built-in ones are `enemy_killed` and `card_equipped`. To react to a **new** kind of
event, add a signal to `GameEvents`, emit it where the event happens, connect it in the
quest manager's `_ready()`, and call `_bump_event("your_quest_id")` from the handler.
Existing handlers are a copy-paste template.

---

## Highlighting card names

In the quest log, known card names in a `description` are automatically turned into
colored, clickable links. To make a name highlightable, add it to `CARD_KEYWORDS` in
`core/quest_system/quest_text_parser.gd`:

```gdscript
const CARD_KEYWORDS := {
    "grenade": "card:grenade",
    "lantern": "card:lantern",
    # "display name (lowercase)": "card:<ability_id>",
}
```

Then just mention the name in a description — `"Throw a grenade at the boss."` — and it
lights up. Matching is case-insensitive and whole-word.

---

## Testing your quest

1. **Run the game** and press **J** (or gamepad **Y**) to open the quest log.
2. Switch to the tab matching your `category`.
3. Confirm the title, description, and progress bar look right.
4. Do the thing the quest tracks (clear the level, get the kills, equip the cards…).
   Progress updates live.
5. When the bar fills, a **Claim** button appears — press it and check the reward lands.

If a quest doesn't show up, the usual cause is an unmet `requires` — it's hidden until
its prerequisites are completed.

---

## Quick reference: full quest template

Copy, paste, fill in:

```gdscript
"q_your_id": {
    "title":        "Your Quest Title",
    "description":  "What the player should do.",
    "category":     "main",            # "main" | "side" | "challenge"
    "type":         "player_data_bool", # see Quest types
    "field":        "some_flag",       # only for player_data_bool / enemy_kills
    "target":       1,
    "reward_coins": 100,
    "reward_card":  "",                # optional res:// card path
    "requires":     [],                # prerequisite quest ids
},
```

That's the whole workflow. Add the entry, (wire a hook if it's an `event` quest), and
the rest is automatic.
