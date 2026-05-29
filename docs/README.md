# Oddside — Implementation Guides

Reference docs for systems, components, and classes in the codebase.

---

## Player Systems

- [`health_component.md`](health_component.md) — health, damage, invulnerability, death signal
- [`energy_component.md`](energy_component.md) — action points, gain/spend, CardSystem wiring
- [`dice_roller_component.md`](dice_roller_component.md) — roll animation, face tracking

## Enemy Systems

- [`enemy_class.md`](enemy_class.md) — base class for all regular enemies, health, player signal hooks
- [`boss_enemy_class.md`](boss_enemy_class.md) — base class for bosses, phases, BOSS DEFEATED banner
- [`enemy_movement_patterns.md`](enemy_movement_patterns.md) — GridMoverComponent setup, patterns, level overrides, animation hooks
- [`grid_mover_component.md`](grid_mover_component.md) — full GridMoverComponent API reference

## World / Level

- [`level_state_system.md`](level_state_system.md) — per-level persistent flags (visited, broken objects, etc.)

## Items & UI

- [`items_and_abilities.md`](items_and_abilities.md) — creating card items and ability scenes
- [`map_system.md`](map_system.md) — map card ability, LevelMapData setup, POIs, reference camera workflow
