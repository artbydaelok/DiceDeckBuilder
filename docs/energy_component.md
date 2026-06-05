# EnergyComponent

A child node component that tracks the player's energy (action points). Energy is gained by rolling and spent when using abilities. Used by Player and CardSystem.

File: `core/components/energy/energy_component.gd`

---

## How to Add to a Scene

1. Add an `EnergyComponent` node as a child of the Player scene.
2. Set `max_energy` in the inspector (default 6 — matches the number of dice faces).
3. Wire passthrough signals in Player's `_ready()`:

```gdscript
@onready var energy_component: EnergyComponent = $EnergyComponent

func _ready():
    energy_component.spent.connect(energy_spent.emit)
    energy_component.gained.connect(energy_gained.emit)
    energy_component.insufficient.connect(insufficient_energy.emit)
```

---

## Exports

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `max_energy` | int | 6 | Maximum energy. Also the starting value. |

---

## API

```gdscript
energy_component.gain(amount: int)          # Add energy, clamped to max.
energy_component.spend(amount: int)         # Remove energy. Emits insufficient if not enough.
energy_component.has_enough(amount: int)    # Returns true if energy >= amount.
energy_component.energy                     # Current energy value (read).
```

---

## Signals

| Signal | Args | When |
|--------|------|------|
| `spent` | `amount: int` | Energy was successfully spent |
| `gained` | `amount: int` | Energy was gained |
| `insufficient` | — | `spend()` was called but there wasn't enough energy |

---

## Usage in CardSystem

CardSystem holds a direct `@export var energy_component: EnergyComponent` — assign it in the inspector. This keeps CardSystem from having to reach through the Player node.

```gdscript
# Before using an ability:
if not energy_component.has_enough(cost):
    energy_component.insufficient.emit()
    return

energy_component.spend(cost)
```

---

## Notes

- Energy starts at `max_energy` on `_ready()`.
- `spend()` checks internally — it won't go below 0 and will emit `insufficient` if the amount isn't available. You can call `has_enough()` first to show UI feedback before attempting the spend.
- The Player re-emits the component's signals as its own passthrough signals (`energy_spent`, `energy_gained`, `insufficient_energy`) so the UI and any external scripts don't need to know about the component.
