# Claude Code Handoff — Oddside (DiceDeckBuilder)

## Project

**Oddside** — a Godot 4.6 3D action game where the player is a die that rolls on a grid. Cards are equipped to dice faces and activate based on trigger types (ON_USE, ON_ROLL, PASSIVE, LINKED). The project is in active development.

Read `docs/README.md` for the index of all implementation guides. Read those docs before touching any system they cover — they are accurate and up to date.

---

## Engine & Stack

- Godot 4.6 custom build
- GDScript only
- Key addons: `dialogue_manager`, `phantom_camera`, `console`, `TweenAnimation`, `assetplacer`, `kanban_tasks`
- No Maaacks Game Template (was removed — all menus are now custom)
- Custom autoloads: `GameEvents`, `DialogueManager`, `SceneLoader`, `ProjectMusicController`, `GlobalCommands`, `Console`, `GlobalSteam`, `MouseLayer`, `SaveSystem`, `PhantomCameraManager`, `CameraZoneManager`, `DiceState`

---

## Architecture Notes

### Player (`player/player.gd`, class `Player extends CharacterBody3D`)
- Movement is **purely code-driven** — no physics gravity, no `move_and_slide`. Grid-based rolling with tweens.
- `cube_size = 2.0` — all grid positions are multiples of 2 in XZ.
- Rolling is delegated to `DiceRoller` component (`$DiceRoller`). Always `await dice_roller.roll(dir)` — never tween the mesh directly.
- Face tracking lives in `dice_roller.faces` (Dictionary: "top"/"bottom"/"left"/"right"/"front"/"back" → int 1–6).
- `detect_side_up()` reads from `dice_roller.faces["top"]` — do NOT revert to the old world-position scan.
- `has_flip: bool` — grants the Flip ability (F key). Set to `true` from story scripts via `player.has_flip = true`.
- `input_disabled`, `rolling`, `commit_lock` are the three guards on all input. Check all three before any new player action.

### Card System (`card/card_system.gd`, class `CardSystem`)
- Player hand is `hand: Array` of 6 slots (null = empty).
- `obtain_new_item(card)` — prefers top face, then random empty, then deck.
- `fire_linked_slot(slot)` — triggers a LINKED card on a specific face.
- Abilities are scenes that extend `Ability`. Use `initialize()` / `_tick()`, not `_ready()` / `_process()`.
- `card_system` is injected into ability instances automatically if the ability has a `card_system` property.

### Checkpoint System (`core/checkpoint_system/`)
- `CheckpointManager` auto-fills `level_name`, `level_path`, `spawn_point` at runtime on player touch. No manual setup needed.
- `checkpoint_fast_traveled` signal on `GameEvents` handles same-level camera restore.
- Cross-level fast travel sets `GameEvents.is_checkpoint_transfer` and `GameEvents.current_checkpoint_data`.

### Map System (`core/map_system/`, `ui/map_display.gd`)
- `LevelMapData` resource: `map_texture`, `map_top_left: Vector2`, `level_dimensions: Vector2`, `points_of_interest: Array[MapPOI]`.
- Assign `current_map_data` on the Level node.
- `world_to_pixel(xz)` converts world XZ → pixel on the map image.
- `MapReferenceCamera` (`core/map_system/map_reference_camera.tscn`) — `@tool` scene, add to level, click "Save Reference PNG" to export a top-down reference for drawing maps in Aseprite. Delete before shipping.

### Vehicle System (`core/vehicles/`)
- `Vehicle extends Node3D` — base class. Carries player by applying `global_position - _last_position` delta each frame. Player movement is code-driven so no AnimatableBody3D needed.
- `MovingPlatform extends Vehicle` — ping-pong between `point_a` / `point_b` Marker3Ds. Only boardable during stop windows. Player is snapped to grid on board.
- Both `LevelVehicle` and `AbilityVehicle` subclasses are planned but not yet implemented.

### Menu System (custom, no Maaacks)
- `SceneLoader` autoload: `res://core/scene_loader.gd` — `load_scene(path)`, `reload_current_scene()`, `scene_loaded` signal.
- `ProjectMusicController` autoload: `res://core/music_controller.gd` — `play_stream(stream)`, `play_stream_player(sp)`, `fade_to_zero()`.
- `run/main_scene` → `res://ui/menus/main_menu/main_menu.tscn`
- Pause menu: `res://ui/menus/pause_menu/pause_menu.tscn` (standalone, no inheritance chain).

### Level Base Class (`levels/game_scene.gd`, `class_name Level`)
- All levels extend `Level`. Override `level_start()`.
- `GameEvents.current_level` is set in `_ready()`.
- `@export var current_map_data: LevelMapData`

---

## Known Issues / TODOs

- `addons/maaacks_game_template/` **must be deleted** from the Godot FileSystem dock if not already done. All references have been updated to custom scripts.
- `leap()` in `player.gd` is unfinished (has a `await get_tree().create_timer(1)` placeholder).
- Options and Credits buttons in main menu are no-ops — options menu not yet implemented.
- `AbilityVehicle` and `LevelVehicle` subclasses of Vehicle are designed but not coded.
- Map system has no fog-of-war yet.
- Flip ability animation: spin happens at peak of jump. If it looks wrong in-game, tweak `flip_duration` in `dice_roller.gd` and the jump arc timing in `player._perform_flip()`.
- Boarding collision layer for `moving_platform.tscn` is set to mask layer 2 — verify this matches the player's physics layer in your project.

---

## Pending Tasks (from task list)

- #11 Design the Oddball level layout and progression
- #12 Implement baseball projectile and hit detection
- #13 Implement three-strike system and run restart
- #14 Build obstacle spawning and speed escalation

These are all part of the **Oddball level** — a baseball-themed level. No work has been done on this yet.

---

## Docs

All system docs are in `docs/`. Start with `docs/README.md`.

Key files to read before working on specific systems:
- Cards/abilities → `docs/items_and_abilities.md`
- Enemies → `docs/enemy_class.md`, `docs/enemy_movement_patterns.md`
- Map → `docs/map_system.md`
- Vehicles → `docs/vehicle_system.md`
- Save/flags → `docs/level_state_system.md`

---

## Style Rules

- GDScript 4. Use `:=` only when type can be inferred without ambiguity. Prefer explicit types on variables that feed into typed contexts.
- Never use `var slot := player.up_side` — `player` is typed as `Node` in some contexts, causing inference failures. Use `var slot: int = player.up_side`.
- Use `_snake_case` for private functions and variables.
- `_ready()` / `_process()` in base classes delegate to `vehicle_ready()` / `vehicle_process()` etc. Subclasses override those hooks, not the Godot built-ins.
- Don't use `ResourceSaver.save()` at runtime — it fails silently in exported builds. Compute values from runtime context instead.
