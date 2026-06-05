# Enemy Class

The base class for all regular (non-boss) enemies in Oddside. Provides health, damage handling, and player signal hooks. Extend this to create new enemies.

File: `enemy/enemy_pawns/base_enemy_pawn.gd`
Class name: `Enemy`
Extends: `CharacterBody3D`

---

## Class Hierarchy

```
CharacterBody3D
  └── Enemy (base_enemy_pawn.gd)
        ├── frog_enemy.gd
        └── GridMoverBase (grid_mover_base.gd)
              └── eyeball.gd
```

---

## Creating a New Enemy

1. Create a new scene with a `CharacterBody3D` root.
2. At the top of the script, write `extends Enemy`.
3. Override the functions you need (see Overridable Functions below).
4. Set `max_health` in the inspector.

```gdscript
extends Enemy

func initialize():
    # Called once on _ready. Set up timers, connect signals, etc.
    pass

func _on_player_rolled():
    # Called each time the player finishes a roll.
    move_toward_player()
```

---

## Exports

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `max_health` | int | 1 | Starting and maximum health |
| `move_speed` | float | 2.0 | Movement speed (2.0 = one grid cell) |

---

## Built-in Variables

```gdscript
current_health   # int — current health value
player           # Node reference to the Player (set in _ready)
initial_height   # float — Y position on spawn, used to keep enemies on the ground
```

---

## Overridable Functions

| Function | When it runs |
|----------|-------------|
| `initialize()` | Once, at the end of `_ready()` |
| `_on_player_moved(direction: Vector3)` | When the player starts a move |
| `_on_player_rolled()` | When the player finishes a roll |
| `tick(delta)` | Every physics frame |
| `on_died()` | When health reaches 0 — calls `queue_free()` by default |

Override `on_died()` if you need a death animation or event before freeing:

```gdscript
func on_died():
    animation_player.play("death")
    await animation_player.animation_finished
    super.on_died()   # calls queue_free()
```

---

## API

```gdscript
apply_damage(amount: int)       # Deal damage. Emits died and calls on_died() if health hits 0.
grid_move_in_direction(dir)     # Tween-move one cell in a direction.
free_move_in_direction(dir)     # Set velocity for free movement (used with move_and_slide).
```

---

## Signals

| Signal | Args | When |
|--------|------|------|
| `died` | — | Health reached 0 |

---

## Notes

- The `player` reference is resolved via `get_tree().get_first_node_in_group("player")` — make sure the Player node is in the `"player"` group.
- `apply_damage` currently has no invulnerability window. Add a timer in `initialize()` and guard in your override if you need one.
- For enemies that move on a grid pattern, use `GridMoverComponent` as a child instead of calling `grid_move_in_direction` manually. See `grid_mover_component.md`.
