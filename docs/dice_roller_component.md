# DiceRoller Component

A child node component that handles the roll tween animation and face tracking for the player's dice mesh. Keeps animation and face state out of `player.gd`.

File: `core/components/dice_roller/dice_roller.gd`

---

## How to Add to a Scene

1. Add a `DiceRoller` node as a child of the Player scene.
2. Assign `pivot` (the `Pivot` Node3D) and `mesh` (the `MeshInstance3D`) in the inspector.
3. Optionally adjust `cube_size` and `speed`.

In `player.gd`, the roll is awaited:

```gdscript
@onready var dice_roller: DiceRoller = $DiceRoller

# To roll:
await dice_roller.roll(direction)
```

---

## Exports

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `pivot` | Node3D | — | The rotation anchor node |
| `mesh` | MeshInstance3D | — | The dice mesh being rotated |
| `cube_size` | float | 2.0 | Size of one grid cell |
| `speed` | float | 4.0 | Roll speed (higher = faster) |

---

## API

```gdscript
await dice_roller.roll(dir: Vector3)   # Animate a roll in dir and update face tracking. Awaitable.
dice_roller.faces                      # Dictionary of current face positions (read).
```

The `faces` dictionary always has these keys: `"top"`, `"bottom"`, `"left"`, `"right"`, `"front"`, `"back"`. Values are face numbers 1–6.

```gdscript
dice_roller.faces["top"]    # Which face number is currently on top
dice_roller.faces["front"]  # Which face is facing forward
```

---

## Signals

| Signal | Args | When |
|--------|------|------|
| `roll_completed` | — | Tween finished and faces updated |

---

## Passthrough on Player

`player.gd` exposes a passthrough property so external scripts don't need to know about DiceRoller:

```gdscript
# In player.gd
var faces: Dictionary:
    get: return dice_roller.faces

# External scripts can still do:
player.faces["top"]
```

---

## Notes

- Starting face layout: top=2, bottom=5, left=6, right=1, front=3, back=4.
- Face tracking is updated after the tween completes, before the position is finalised — so `roll_completed` fires with the correct new face values already in `faces`.
