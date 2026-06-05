# Vehicle System

Vehicles are Node3D objects the player can stand on and be carried by. Movement is handled by manually applying the vehicle's frame delta to the player's position each frame — no physics velocity inheritance.

---

## Files

| File | Purpose |
|------|---------|
| `core/vehicles/vehicle.gd` | Base class for all vehicles |
| `core/vehicles/moving_platform.gd` | Ping-pong platform (Crash Bandicoot-style) |
| `core/vehicles/moving_platform.tscn` | Ready-to-place moving platform scene |

---

## How It Works

Every frame the vehicle calculates how far it moved since the previous frame and adds that delta directly to the player's `global_position`:

```gdscript
var delta_pos := global_position - _last_position
current_player.global_position += delta_pos
```

This means the player is always in sync with the vehicle regardless of how the vehicle moves — tweens, sine waves, scripted paths, anything.

Boarding is detected via an `Area3D` child on the vehicle. When the player's `CharacterBody3D` enters it during a boardable window, they're snapped to the nearest grid position and carried from that point on.

---

## Vehicle Base Class (`vehicle.gd`)

All vehicles extend this. It handles delta tracking, player carrying, boarding/disembark detection, and grid snapping.

### Key properties

```gdscript
is_boardable: bool       # Set true to open the boarding window
current_player: Player   # The player currently on board, or null
```

### Signals

| Signal | Args | When |
|--------|------|------|
| `player_boarded` | `player: Player` | A player successfully boarded |
| `player_disembarked` | `player: Player` | The player left the vehicle |

### Overridable hooks

| Function | When it runs |
|----------|-------------|
| `vehicle_ready()` | At the end of `_ready()` |
| `vehicle_process(delta)` | Every frame (use instead of `_process`) |
| `on_player_boarded(player)` | After boarding is confirmed |
| `on_player_disembarked(player)` | After the player leaves |

### API

```gdscript
force_board(player)      # Board a player immediately, bypassing the Area3D.
                         # Used by ability-spawned vehicles (e.g. skateboard).
force_disembark()        # Eject the current player.
```

---

## Moving Platform (`moving_platform.gd`)

Ping-pongs between two `Marker3D` waypoints. Pauses at each end for a configurable window during which the player can board or disembark.

### Setting up in a level

1. Add `moving_platform.tscn` to your level scene.
2. Add two `Marker3D` nodes at the start and end positions. **Both must be at grid-aligned XZ coordinates** (multiples of 2.0) so the player can step off onto valid grid spots.
3. Assign them to **Point A** and **Point B** in the inspector.
4. Tune the timing exports.

### Exports

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `point_a` | Marker3D | — | Start position |
| `point_b` | Marker3D | — | End position |
| `travel_duration` | float | 2.0 | Seconds to travel between points |
| `stop_duration` | float | 1.5 | Seconds the platform waits at each end (boarding window) |
| `ease_type` | enum | Sine | Travel easing: Linear, Sine, Bounce, Spring |
| `autostart` | bool | true | Start moving on `_ready`. Set false to call `start()` manually. |

### Boarding rules

- The platform is only boardable (`is_boardable = true`) while stopped at either end.
- The player can walk off the edge at any time. If the platform is mid-transit, they simply leave — the platform doesn't stop for them.
- On boarding, the player's XZ position is snapped to the nearest grid cell (multiples of 2.0).

### Extending it

Create a new script that extends `MovingPlatform` and override the hooks:

```gdscript
extends MovingPlatform

func on_player_boarded(player: Player) -> void:
    $CreakSFX.play()
    $AnimationPlayer.play("tilt")

func on_player_disembarked(player: Player) -> void:
    $AnimationPlayer.play("settle")
```

---

## Collision Layer Setup

The `BoardingArea` on `moving_platform.tscn` has its **collision mask set to layer 2**. Make sure the player's `CharacterBody3D` is assigned to **physics layer 2**, or change the mask to match your project's layer setup.

---

## Creating a New Vehicle Type

1. Create a new script extending `Vehicle` (or `MovingPlatform` if it's a platform variant).
2. Override `vehicle_ready()` to set up initial state.
3. Override `vehicle_process(delta)` to drive movement — update `global_position` however you like.
4. Set `is_boardable = true` when you want the player to be able to get on.
5. Create a scene with a mesh, a `StaticBody3D` for collision, and an `Area3D` for boarding detection.

```gdscript
extends Vehicle

func vehicle_ready() -> void:
    is_boardable = true  # Always boardable (e.g. a stationary raft)

func vehicle_process(delta: float) -> void:
    # Drift along the river
    global_position.x += river_speed * delta
```

---

## Planned Subclasses

| Class | Description |
|-------|-------------|
| `LevelVehicle` | Vehicle that IS the level floor (raft, spaceship, carpet). Player on from start, no boarding. |
| `AbilityVehicle` | Spawned by a card ability (e.g. skateboard). Uses `force_board()` immediately, overrides player locomotion, resolves back to grid on dismount. |
