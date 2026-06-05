# Oddside — Level Authoring Brief (for a level planner / builder tool)

A reference for building a tool that **plans** and/or **generates** Oddside levels.
Oddside is a Godot 4.6 (GL Compatibility) 3D game where the player is a **die that
rolls on a grid**. Levels are `.tscn` scenes. This doc describes the grid model, the
canonical level scene structure, the placeable building blocks, and a suggested
data model for a level plan.

> Sister project note: this brief is Oddside-specific. Sluggerpunk is a different
> codebase with its own structures — don't assume these paths/classes there.

---

## 1. Coordinate & grid model (the single most important thing)

- The player die is **`cube_size = 2.0`** units. **All grid positions are multiples of 2 on the X and Z axes.** One "tile" = 2 world units.
- Movement is **code-driven**, grid-based rolling — **no physics gravity, no `move_and_slide`**. The die tweens one tile per roll.
- The floor/board sits at **y = 0**; the die's mesh center rests at **y = cube_size/2 = 1**.
- A tile coordinate `(tx, tz)` maps to world position **`(tx * 2, 0, tz * 2)`**. A planner should work in integer tile coordinates and multiply by 2 on export.
- Directions: `Vector3.FORWARD` is −Z. The die tracks its six faces in a dictionary (`top/bottom/left/right/front/back` → 1–6); a builder never needs to set this.

**Rule for any generator: snap every placed entity's X/Z to multiples of 2.**

---

## 2. Canonical level scene structure

Levels follow the template **`res://levels/game_scene.tscn`** (root script
`res://levels/game_scene.gd`, `class_name Level`). Existing levels live in
`res://levels/` (e.g. `forest_level/forest_level.tscn`, `street_level.tscn`,
`hub_level.tscn`, boss levels). The tree:

```
Game (Node3D, script = game_scene.gd : Level)         # @export level_name, current_map_data, game_camera
├── PauseController (pause_menu_controller.gd)
├── CardSystem (instance res://card/card_system.tscn)  # player + energy_component node paths
├── UI (CanvasLayer, group "user_interface")           # health, energy, coins, AbilitySidesDisplay
├── ItemPickupPopup (CanvasLayer)
├── BaseLevel (Node3D, group "entities_layer")
│   ├── Player (instance res://player/player.tscn, group "player")
│   ├── Cameras
│   │   ├── PlayerCamera (PhantomCamera3D, follows the die)
│   │   └── GameCamera (Camera3D, group "game_camera", current)
│   ├── Lights (DirectionalLight3D ×2)
│   ├── Enemies (Node3D)        # ← enemy instances go here
│   ├── Environment (Node3D)    # ← level geometry / floor / WorldEnvironment
│   ├── VisualEffects (Node3D)
│   ├── Gameplay (Node3D)       # ← pickups, deck zones, triggers, vehicles, breakables
│   └── NPCs (Node3D)           # ← dialogue NPCs
├── CRTShaderLayer / PSXShaderLayer (post-processing)
```

**A builder fills the container nodes** (`Environment`, `Enemies`, `Gameplay`, `NPCs`).
The rest of the tree (player, cameras, UI, shaders) is fixed boilerplate — start from a
copy of `game_scene.tscn` rather than generating it from scratch.

Levels are loaded by path via the **`SceneLoader`** autoload: `SceneLoader.load_scene("res://levels/...")`. `run/main_scene` is the main menu, not a level.

---

## 3. Placeable building blocks (the "palette")

Instance these under the noted container. Set X/Z to multiples of 2.

| Block | Scene / script | Container | Key exports / notes |
|-------|----------------|-----------|---------------------|
| **Enemy (pawn)** | `res://enemy/enemy_pawns/<type>/<type>.tscn` (eyeball, frog, flying_imp, shooting_goon) | `Enemies` | `max_health`, `move_speed`, `enemy_id` (kill-tracking id; defaults to scene filename). Base class `Enemy` (`base_enemy_pawn.gd`). |
| **Boss** | `res://enemy/boss/<name>/...` (bear, fire_demon, forest_demon, jim_and_jam, salt_and_pepper) | `Enemies` | Extends `BossEnemy` (Node3D). One per arena. |
| **Item pickup** | `res://level_mechanics/item_pickup.tscn` | `Gameplay` | `item_data: Card` — the card granted on touch. Area3D on collision_mask 256. |
| **Coin pickup** | `res://level_mechanics/coin_pickup.gd` | `Gameplay` | grants currency. |
| **Deck zone** (puzzle loadout) | `res://level_mechanics/deck_zone.tscn` | `Gameplay` | `deck: Deck` — swaps the die's 6 faces to a puzzle deck while inside, restores on exit. Decks in `res://card/decks/` (color/poker/directions). |
| **Breakable / log** | `res://level_mechanics/breakable.gd`, `breakable_log.gd` | `Gameplay`/`Environment` | destructible obstacle (collision layer 6 "Breakable"). |
| **Moving platform** | `res://core/vehicles/moving_platform.tscn` | `Gameplay` | ping-pongs between `point_a`/`point_b` Marker3Ds; carries the die. Base class `Vehicle`. |
| **Water / lilypad** | `res://level_mechanics/water_block.gd`, `lilypad_platform.gd` | `Environment`/`Gameplay` | water hazard + ridable lilypads. |
| **Camera zone** | `res://level_mechanics/camera_angle_change/camera_zone.gd` (+ `camera_angle_holder.gd`) | `Cameras`/`Gameplay` | Area3D that changes camera framing on entry. |
| **Checkpoint** | `res://core/checkpoint_system/...` | `Gameplay` | `CheckpointManager` auto-fills `level_name`/`spawn_point` at runtime — just place it. |
| **Dialogue NPC / trigger** | DialogueManager + `.dialogue` files in `res://dialogue/` | `NPCs` | story beats; can set flags like `player.has_flip = true`. |
| **Debug player start** | `res://level_mechanics/debug_player_start.gd` | `BaseLevel` | overrides spawn for testing. |

Floor/geometry in existing levels is built with **CSG nodes** + a `Sprite3D` grid texture
under `Environment`, and placed props via the **AssetPlacer** addon. A builder can emit
`CSGBox3D`/`GridMap`-style geometry or placeholder boxes snapped to the 2-unit grid.

---

## 4. Collision layers (from `project.godot`)

| Layer | Name | Mask value |
|------:|------|-----------:|
| 2 | PlayerProjectiles | 2 |
| 3 | EnemyProjectiles | 4 |
| 4 | PlayerHurtbox | 8 |
| 5 | EnemyHurtbox | 16 |
| 6 | Breakable | 32 |
| 8 | explosion_blast | 128 |
| 9 | **PlayerInteraction** | **256** |

Trigger areas that should detect the player (pickups, deck zones, camera zones) use
**`collision_layer = 0`, `collision_mask = 256`** (the player carries an interaction
area on layer 9).

---

## 5. `.tscn` / `.tres` format notes for a generator

- Scenes and resources are **text**. Instance a scene with an `ext_resource` of
  `type="PackedScene"` and a `[node ... instance=ExtResource("id")]`.
- Reference assets by **`uid://`** when known (stable across moves) or by `res://` path.
  **Never strip an existing resource's `uid="..."` header** when rewriting it — dangling
  uids break `preload("uid://…")` references elsewhere. (Learned the hard way.)
- Typed resource arrays serialize as
  `field = Array[ExtResource("script_id")]([ExtResource("a"), ExtResource("b")])`.
- A new `class_name` (e.g. a generated resource type) only resolves after the **editor
  reimports** (regenerates `.godot/global_script_class_cache.cfg`). Generating resources
  headless before that import will throw "Could not find type X" until the editor opens.
- Don't validate by running the **headless editor import** over the whole project — it can
  silently re-save unrelated scenes and drop data. Prefer `--check-only --script <file>`
  for parse checks, or a `SceneTree` `--script` tool for resource generation.

---

## 6. Minimap / map data

- `LevelMapData` resource (`res://core/map_system/...`): `map_texture`, `map_top_left: Vector2`,
  `level_dimensions: Vector2`, `points_of_interest: Array[MapPOI]`. Assigned to the level's
  `current_map_data` export.
- `world_to_pixel(xz)` converts world XZ → map-image pixel. A planner that knows the tile
  grid can also emit POIs and map metadata.

---

## 7. Suggested level-plan data model (for the planner half)

A clean intermediate the planner produces and the builder consumes. Tile-based, engine-agnostic:

```jsonc
{
  "level_name": "Forest Clearing",
  "scene_path": "res://levels/forest_clearing.tscn",
  "grid": { "width": 12, "depth": 16 },          // in tiles (×2 = world units)
  "tiles": [                                       // optional: floor/terrain layer
    { "x": 0, "z": 0, "type": "floor" },
    { "x": 4, "z": 6, "type": "water" }
  ],
  "entities": [                                    // everything placeable
    { "kind": "enemy", "id": "frog_enemy", "x": 6, "z": 8, "props": { "max_health": 2 } },
    { "kind": "item_pickup", "card": "res://card/.../grenade.tres", "x": 2, "z": 2 },
    { "kind": "deck_zone", "deck": "res://card/decks/color_deck_6.tres", "x": 10, "z": 4 },
    { "kind": "checkpoint", "x": 0, "z": 0 },
    { "kind": "moving_platform", "x": 8, "z": 8, "point_b": [8, 14] }
  ],
  "map_data": { "dimensions": [24, 32] }
}
```

Builder algorithm: copy `game_scene.tscn` → set `level_name`/`current_map_data` → for each
entity, add an `ext_resource` for its scene/script and a `[node ... parent="BaseLevel/<container>"]`
with `transform` placing it at `(x*2, y, z*2)` and its `props` as overrides. Keep the player,
cameras, UI, and shader layers untouched.

---

## 8. Conventions & gotchas

- **Grid-snap everything** to multiples of 2 on X/Z; floor at y = 0, die center at y = 1.
- Movement is **purely code-driven** — don't add gravity/`move_and_slide`, `RigidBody`, or
  navmeshes for the die.
- The player, card system, cameras, and UI are **boilerplate from the template** — generate
  only the contents of `Environment`/`Enemies`/`Gameplay`/`NPCs`.
- Bosses get their own arena level; pawns populate `Enemies`.
- `view_deck` input opens the dice inventory editor (level handles this) — not a level concern.
- A `MapReferenceCamera` (`@tool`) can export a top-down PNG of a level for drawing the
  minimap; delete it before shipping.
- Autoloads a level relies on: `GameEvents`, `SceneLoader`, `SaveSystem`, `DiceState`,
  `PhantomCameraManager`, `CameraZoneManager`, `DialogueManager` (+ new `QuestManager`/`QuestDatabase`).

---

## 9. What a builder should NOT auto-decide
- Combat balance / enemy counts (design-driven).
- Camera framing per zone (hand-tuned).
- Story/dialogue flow.
Generate the *structure and placement*; leave tuning to the editor.
