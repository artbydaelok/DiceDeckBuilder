# Oddside Level Planner

Top-down **XZ tile** editor for Oddside (`DiceDeckBuilder`). Plans are engine-agnostic JSON; a future Godot builder will clone `game_scene.tscn` and place entities at `x * 2`, `z * 2` world units.

## Quick start

**Easiest:** double-click `Run Oddside Level Planner.bat` in the game folder (`DiceDeckBuilder`).

Or from a terminal:

```bash
cd tools/oddside-level-planner
npm install
npm run icons      # placeholder sprites from game-icons.net (CC BY 3.0)
npm run catalog    # scan enemy/deck scenes from the game project
npm run dev        # http://localhost:5173
```

Grid and palette icons are from [game-icons.net](https://game-icons.net) ([CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)); they are planner-only and are not exported to Godot.

Each enemy and boss has its own icon under `public/icons/enemies/`. To change or add mappings, edit `scripts/enemy-icon-map.mjs`, then run `npm run icons` and `npm run catalog`.

- **Click** — place entity (from palette) or select existing  
- **Alt+click / right-click** — remove entity on that cell  
- **Terrain paint** — toggle tile types (floor, water, …)  
- **Export JSON** — save next to levels under `level_plans/`  

Example plan: `level_plans/example_arena.plan.json`

## Regenerate asset catalog

When you add enemies, bosses, or decks in Godot:

```bash
npm run catalog
```

Writes `public/catalog.json` from `enemy/enemy_pawns`, `enemy/boss`, and `card/decks`.

## Plan format (version 2)

| Field | Meaning |
|-------|---------|
| `size` | Footprint in tiles (width × depth), top-left at `x`,`z` |
| `path` | Waypoints for moving platforms (grid tiles) |
| `grid_mover` | Enemy patrol / chase config |
| `editor_only` | If true, stripped from **Export for Godot** |
| `props.deck` | Deck zone: which `Deck` `.tres` replaces faces |
| `props.object_id` | Breakable: unique save flag per level |

**Placement:** point (click), rectangle (drag), path (clicks + Finish path).

**Export for Godot** omits `editor_region` entities. Use **Export full plan** to keep layout notes.

See `schema/level-plan.schema.json`. Validated in-app with Ajv.

## Roadmap (in-game)

| Milestone | Description |
|-----------|-------------|
| **M1** (this tool) | Plan JSON + validation |
| **M2** | `@tool` or CLI script: `game_scene.tscn` → apply `entities[]` |
| **M3** | Reverse import: parse existing level → plan (harder; forest_level is prop-heavy) |

Do not run headless `--import` on the whole project; it can resave unrelated scenes.
