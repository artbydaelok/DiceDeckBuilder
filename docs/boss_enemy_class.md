# BossEnemy Class

The base class for all boss enemies in Oddside. Provides health, damage, and death handling for complex multi-phase bosses. Distinct from the regular `Enemy` class — bosses are `Node3D`, not `CharacterBody3D`, because they orchestrate phases and animations rather than moving on a physics grid.

File: `enemy/boss/boss_enemy.gd`
Class name: `BossEnemy`
Extends: `Node3D`

---

## Class Hierarchy

```
Node3D
  └── BossEnemy (boss_enemy.gd)
        ├── bear_boss.gd
        ├── fire_demon_boss.gd
        ├── jim_and_jam.gd
        └── salt_and_pepper.gd

Note: forest_demon.gd extends Node3D directly (no BossEnemy).
```

---

## Creating a New Boss

1. Create a new scene with a `Node3D` root.
2. At the top of the script: `extends BossEnemy`.
3. Assign `user_interface` and `max_health` in the inspector.
4. Override `initialize()`, `on_damage_taken()`, and `on_died()`.

```gdscript
extends BossEnemy

func initialize():
    # Called once in _ready. Start first phase, connect signals, etc.
    start_phase_one()

func on_damage_taken(amount):
    # React to being hit — flash sprite, trigger phase change, etc.
    if current_health < max_health / 2:
        start_phase_two()

func on_died():
    # Play death sequence. Base class handles BOSS DEFEATED banner.
    animation_player.play("death")
```

---

## Exports

| Export | Type | Description |
|--------|------|-------------|
| `max_health` | int | Starting and maximum health (default 100) |
| `user_interface` | CanvasLayer | The UI layer for the BOSS DEFEATED banner |

---

## Built-in Variables

```gdscript
current_health   # int — current health value
player           # Node reference to the Player
entities_layer   # Node3D reference to the entities layer
```

---

## Overridable Functions

| Function | When it runs |
|----------|-------------|
| `initialize()` | Once, at the end of `_ready()` |
| `on_damage_taken(damage_amount)` | After every hit that lands |
| `on_died()` | When health drops below 0 |

---

## API

```gdscript
apply_damage(damage_amount)   # Deal damage. Fires health_updated, then died if health < 0.
```

---

## Signals

| Signal | Args | When |
|--------|------|------|
| `health_updated` | `health_change, new_current_health` | Any time damage is applied |
| `died` | — | Health dropped below 0 |

---

## Notes

- The **BOSS DEFEATED** banner fires automatically on death via `user_interface` — make sure to assign it in the inspector, otherwise the banner will not appear.
- The base `apply_damage` does NOT call `queue_free()`. Clean up the boss in your `on_died()` override.
- `player` and `entities_layer` are resolved via group lookups (`"player"`, `"entities_layer"`) on `_ready()`.
