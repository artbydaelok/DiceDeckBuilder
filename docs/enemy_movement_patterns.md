# Enemy Movement Patterns

How to add grid-based movement to an enemy using `GridMoverComponent`. Covers pattern setup, level overrides, animation hooks, and the two existing examples (Frog, Eyeball).

For the full `GridMoverComponent` API, see `grid_mover_component.md`.

---

## The Short Version

1. Add a `GridMoverComponent` node as a child of your enemy scene.
2. Leave `target` empty — it defaults to the parent.
3. Set the pattern and trigger mode either in the base scene (shared default) or per-instance in the level (override).
4. Connect `step_started` / `step_finished` in `initialize()` for animations.

---

## Setting Up the Component

In the enemy's base `.tscn`:
- Add `GridMoverComponent` as a child of the root node.
- Set sensible defaults: `move_speed`, `interval_time`, `autostart`.
- Leave `pattern` empty if instances will each have their own.

In the enemy script's `initialize()`:

```gdscript
@onready var grid_mover: GridMoverComponent = $GridMoverComponent

func initialize() -> void:
    grid_mover.step_started.connect(func(_dir): animation_player.play("walk"))
    grid_mover.step_finished.connect(func(_dir): animation_player.play("idle"))
```

---

## Pattern Configuration

The `pattern` is an `Array[Vector3]` of normalized direction vectors. The component steps through them in order.

| Pattern | Behaviour |
|---------|-----------|
| `[BACK, BACK, BACK]` | Move 3 steps forward, loop |
| `[BACK, BACK, BACK]` + `ping_pong = true` | Move 3 steps forward, then 3 back, repeat |
| `[BACK, RIGHT, FORWARD, LEFT]` | Walk a square |
| empty + `chase_player = true` | Follow the player's direction on each trigger |

Set direction vectors in the inspector using normalized values: `(0,0,1)` = BACK, `(0,0,-1)` = FORWARD, `(1,0,0)` = RIGHT, `(-1,0,0)` = LEFT.

---

## Per-Instance Patterns in a Level

If the base scene has a `GridMoverComponent` with an empty pattern, each instance placed in a level can have its own:

1. Place the enemy in the level scene.
2. Expand the instance in the scene tree to reveal its `GridMoverComponent` child.
3. Set the `Pattern` array and any other settings on that child.

These are stored as scene overrides on the level — the base scene is unchanged.

---

## Existing Examples

### Frog (`frog_enemy.gd`)

Uses runtime pattern building. `spaces_to_move` and `reverse_direction` are designer-facing exports. `autostart = false` on the component. `initialize()` builds the array, sets `ping_pong_pattern = true`, and calls `start()`. Plays `"jump"` animation on `step_started`.

### Eyeball (`eyeball.gd`)

Stationary by default — `GridMoverComponent` is present but pattern is empty until set per-instance in the level. `react_to_player_move = true` on each instance so movement only triggers when the player moves. The eyeball's core behaviour (player repositioning) is handled separately via a `Hitbox`.

---

## Notes

- `move()` is safe to call at any time — it's a no-op while `moving` is true, so you can't accidentally double-step.
- Height (Y) is always preserved — movement is XZ only.
- `rotate_to_face_direction` smoothly rotates the enemy to face each step direction, over the same duration as the tween.
