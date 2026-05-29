# Items & Abilities

How to create a new item (card) with a custom ability that the player can use.

---

## Overview

Each item has two parts:

- A **Card resource** (`.tres`) — holds the data: name, description, artwork, cost, etc.
- An **Ability scene** (`.tscn`) — the node instantiated when the item is used. Contains the actual logic.

The Card resource references the Ability scene via `ability_id`. When the player uses the item, `CardSystem` instantiates that scene and calls `initialize()` on it.

---

## Step 1: Create the Card Resource

Navigate to `card/card_abilities/` and right-click → **New Resource** → search `Card`.

Fill in the fields:

| Field | Description |
|-------|-------------|
| `card_name` | Display name |
| `card_description` | Short flavour/description text |
| `card_artwork` | Texture2D shown in the HUD and pickup popup |
| `cost` | Energy cost to use this ability |
| `commit_value` | Seconds player input is disabled while the ability plays out |
| `value` | Shop price (can be 0 if not sold in shops) |
| `trigger_type` | How the card activates — see Trigger Types below |
| `ability_id` | Path to the Ability `.tscn` (e.g. `res://abilities/my_ability/my_ability.tscn`) |

### Trigger Types

| Type | When it activates |
|------|------------------|
| `ON_USE` | Player manually activates it (spends energy) |
| `ON_ROLL` | Fires automatically when that face is rolled |
| `PASSIVE` | Always active while on any face |
| `LINKED` | Triggered by another card's ability calling `fire_linked_slot()` |

---

## Step 2: Create the Ability Scene

Navigate to `abilities/` and create a folder for your new ability. Inside it, create a new scene that **inherits from** `abilities/ability_base/ability.tscn`.

Add a new script extending `Ability`:

```gdscript
extends Ability

func initialize() -> void:
    # Called once when the ability is spawned.
    # Use this instead of _ready().
    do_something()
    queue_free()  # call this when the ability is done

func _tick(delta: float) -> void:
    # Called every frame. Use this instead of _process().
    pass
```

**Important:** Use `initialize()` and `_tick()` instead of `_ready()` and `_process()`. The base `Ability` class sets those up internally.

### Built-in Variables (from Ability base)

```gdscript
player           # Reference to the Player node
card_system      # Reference to the CardSystem node
self_destroy_timer  # Timer that auto-frees the ability after commit_value seconds
```

---

## Step 3: Link the Ability Scene to the Card Resource

Open your Card `.tres` and set `ability_id` to the path of your Ability `.tscn`:

```
res://abilities/my_ability/my_ability.tscn
```

---

## Obtaining the Item In-Game

To give the player an item from code:

```gdscript
var card_system = get_tree().get_first_node_in_group("card_system")
card_system.obtain_new_item(MY_CARD_RESOURCE)
```

`obtain_new_item` places it on the top face if empty, otherwise a random empty face, otherwise adds it to the deck.

---

## Notes

- The `commit_value` disables player input for that many seconds after the ability fires. Set it to `0` for instant abilities.
- If your ability needs more time than `commit_value`, call `self_destroy_timer.queue_free()` in `initialize()` to prevent premature cleanup, then call `queue_free()` yourself when done.
- `card_system` is injected automatically if the ability scene has a `card_system` property — no need to find it yourself.
