# Level State System

Level state lets you persist per-level flags across game sessions — things like "has the player visited this level" or "was this barrel already broken". All state lives inside `SaveSystem.player_data.level_states`, keyed by level scene name.

---

## How It Works

Flags are stored as a nested dictionary:

```
level_states = {
  "street_01": {
    "visited": true,
    "log_01_broken": true,
    "barrel_entrance_broken": false
  },
  "alley_02": {
    "visited": false
  }
}
```

The level ID is always `get_tree().current_scene.name` — so make sure your scene files are named clearly and consistently.

---

## Reading and Writing Flags

Use the two helpers on `SaveSystem` from anywhere in the codebase:

```gdscript
# Read a flag (returns default if not set yet)
SaveSystem.get_level_flag("street_01", "visited", false)

# Write a flag
SaveSystem.set_level_flag("street_01", "visited", true)

# Always call save after writing if you want it persisted immediately
SaveSystem.save_player_data()
```

---

## Adding a New Flag — Step by Step

### 1. Simple one-off flag (e.g. "visited")

In your level script's `_ready()`:

```gdscript
var level_id := get_tree().current_scene.name

if not SaveSystem.get_level_flag(level_id, "visited", false):
    SaveSystem.set_level_flag(level_id, "visited", true)
    SaveSystem.save_player_data()
    _on_first_visit()
```

### 2. Breakable object flag

Select the `BreakableComponent` node on your object and set the `object_id` export to a unique string for that level, e.g. `log_01`, `barrel_entrance`.

The component handles the rest automatically:
- On `_ready`: checks if already broken, disables collisions silently if so
- On break: writes the flag and saves

The parent's `broke` signal still fires normally on a fresh break — it will NOT fire on restore. If you need the parent to also hide its mesh on restore, check the flag yourself in the parent's `_ready`:

```gdscript
func _ready():
    var level_id := get_tree().current_scene.name
    if SaveSystem.get_level_flag(level_id, "log_01", false):
        $MeshInstance3D.visible = false
```

### 3. Flags with more than two states

Flags can hold any value, not just booleans:

```gdscript
# Store an integer
SaveSystem.set_level_flag(level_id, "chest_state", 2)

# Store a string
SaveSystem.set_level_flag(level_id, "npc_dialogue_stage", "post_fight")
```

---

## Naming Conventions

| Type | Example key |
|------|-------------|
| Object broken | `log_01`, `barrel_entrance` |
| First visit | `visited` |
| Cutscene seen | `cutscene_intro_seen` |
| NPC state | `npc_shopkeeper_state` |
| Collectible picked up | `coin_alley_hidden` |

Keep keys lowercase with underscores. Include a number suffix for objects that have multiple instances in one level (`crate_01`, `crate_02`).

---

## Notes

- `set_level_flag` does NOT auto-save — call `SaveSystem.save_player_data()` after writing, or batch your writes and save once at a checkpoint/transition.
- The level ID comes from the scene name, not the file path. Rename scenes carefully.
- Flags that don't exist yet return the `default` value passed to `get_level_flag` — no need to pre-declare them anywhere.
