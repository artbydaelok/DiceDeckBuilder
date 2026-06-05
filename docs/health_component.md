# HealthComponent

A child node component that manages health, damage, invulnerability, and death for any node. Used by the Player. Can be added to any scene that needs health.

File: `core/components/health/health_component.gd`

---

## How to Add to a Scene

1. Add a `HealthComponent` node as a child of the scene root.
2. Set `max_health` in the inspector.
3. Set `invulnerability_duration` (seconds the node is immune after taking a hit).
4. Connect signals in the parent's `_ready()`.

```gdscript
@onready var health_component: HealthComponent = $HealthComponent

func _ready():
    health_component.damaged.connect(_on_damaged)
    health_component.died.connect(_on_died)
```

---

## Exports

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `max_health` | int | 100 | Maximum and starting health |
| `invulnerability_duration` | float | 1.0 | Seconds of invulnerability after a hit |

---

## API

```gdscript
health_component.apply_damage(amount: float)   # Deal damage. Respects invulnerability window.
health_component.heal(amount: float)           # Restore health up to max.
health_component.health                        # Current health value (read).
health_component.is_dead                       # Bool — true once health hits 0.
health_component.invulnerable                  # Bool — true during invulnerability window.
```

---

## Signals

| Signal | Args | When |
|--------|------|------|
| `damaged` | `amount: float` | A hit landed and health decreased |
| `healed` | `amount: float` | Heal was applied |
| `health_updated` | `new_health: float` | Any time health changes (damage or heal) |
| `died` | — | Health reached 0 for the first time |

---

## Notes

- `died` fires only once — `is_dead` is checked before applying damage, so dead nodes ignore further hits.
- `apply_damage` does nothing during the invulnerability window. Set `invulnerability_duration = 0` to disable it.
- The component does NOT call `queue_free()` — death cleanup is the parent's responsibility, handled via the `died` signal.
