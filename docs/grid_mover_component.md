# GridMoverComponent

A child node component that moves any Node3D along a grid. Works on enemies, props, platforms — anything. Handles its own timer, wires player signals internally, and emits animation hooks so the parent can react however it wants.

File: `core/components/grid_mover/grid_mover_component.gd`

---

## How to Add to a Scene

1. Add a `GridMoverComponent` node as a child of the scene.
2. Assign `target` in the inspector — or leave it empty and it will default to the parent node.
3. Configure movement in the inspector (pattern, speed, trigger type).
4. Connect signals to drive animations.

```gdscript
@onready var grid_mover: GridMoverComponent = $GridMoverComponent

func _ready():
    grid_mover.step_started.connect(_on_step_started)
    grid_mover.step_finished.connect(_on_step_finished)

func _on_step_started(direction: Vector3):
    animation_player.play("walk")

func _on_step_finished(direction: Vector3):
    animation_player.play("idle")
```

---

## Exports

### Movement

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `target` | Node3D | null (→ parent) | The node to move |
| `cell_size` | float | 2.0 | World units per grid cell |
| `move_speed` | float | 4.0 | Steps per second (higher = faster) |

### Pattern

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `pattern` | Array[Vector3] | [] | Sequence of directions to cycle through |
| `ping_pong_pattern` | bool | false | Reverse pattern direction at the end instead of looping |
| `chase_player` | bool | false | Move in the player's direction on each trigger |

### Trigger

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `react_to_player_move` | bool | false | Trigger on player move instead of timer |
| `interval_time` | float | 0.75 | Seconds between steps when using the timer |
| `autostart` | bool | true | Start the timer automatically on `_ready()` |

### Rotation

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `rotate_to_face_direction` | bool | false | Smoothly rotate target to face movement direction |

---

## API

```gdscript
grid_mover.move(direction: Vector3)   # Trigger one step in the given direction. Does nothing if already moving.
grid_mover.pattern_move()             # Advance one step through the configured pattern.
grid_mover.start()                    # Start the internal timer (use when autostart = false).
grid_mover.moving                     # Bool — true while a tween is in progress (read).
```

---

## Signals

| Signal | Args | When |
|--------|------|------|
| `step_started` | `direction: Vector3` | Tween begins — good for starting walk/jump animations |
| `step_finished` | `direction: Vector3` | Tween ends and node has arrived — good for idle/land animations |

---

## Usage Examples

### Pattern movement on a timer

Set `pattern = [Vector3.BACK, Vector3.BACK, Vector3.FORWARD, Vector3.FORWARD]`, `interval_time = 1.0`. The node will step through that sequence on its own with no code required.

### Reacting to the player

Set `react_to_player_move = true` and `chase_player = true`. The node will move in the same direction the player moved on each roll.

### Building the pattern at runtime (from exports)

If the pattern depends on another export (like `spaces_to_move`), build it in `initialize()` with `autostart = false`:

```gdscript
@export var spaces_to_move: int = 3
@export var reverse_direction: bool = false

func initialize() -> void:
    var dir := Vector3.FORWARD if reverse_direction else Vector3.BACK
    for i in spaces_to_move:
        grid_mover.pattern.append(dir)
    grid_mover.ping_pong_pattern = true
    grid_mover.interval_time = 1.0 / move_speed
    grid_mover.step_started.connect(func(_dir): animation_player.play("jump"))
    grid_mover.start()
```

Set `Autostart = false` on the GridMoverComponent in the inspector when doing this — otherwise the timer fires before the pattern is built.

### Per-instance patterns in a level

If the base scene has a GridMoverComponent with an empty pattern, each instance placed in a level can have its own:

1. Place the enemy in the level scene.
2. Expand the instance in the scene tree to reveal its `GridMoverComponent` child.
3. Set the `Pattern` array and any other settings on that child.

These are stored as scene overrides on the level — the base scene is unchanged. This is how the Eyeball enemies work in the forest level.

### Calling from code manually

You can ignore pattern/timer entirely and just call `move()` yourself:

```gdscript
func on_jump_timer_timeout():
    grid_mover.move(move_direction)
```

---

## Trigger Mode Summary

| Mode | How to set | When it moves |
|------|-----------|---------------|
| **Timer** (default) | `react_to_player_move = false` | Every `interval_time` seconds |
| **On player move** | `react_to_player_move = true` | Each time the player rolls |
| **Chase player** | `react_to_player_move = true`, `chase_player = true` | Moves in the same direction the player moved |
| **Manual** | Call `grid_mover.move(dir)` from code | Whenever you call it |

---

## Notes

- The component creates its own `Timer` node internally — you do not need a Timer child in your scene.
- `move()` is a no-op if `moving` is true — safe to call every frame or from a timer without double-stepping.
- Height (Y position) is preserved — the component always moves along the XZ plane.
- `rotate_to_face_direction` tweens the Y rotation over the same duration as the step, so they finish together.
