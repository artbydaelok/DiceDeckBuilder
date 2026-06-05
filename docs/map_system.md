# Map System

The map is a **Card item** the player equips on a dice face. When used (`ON_USE` trigger), it opens a full-screen map overlay showing the hand-drawn level map, the player's position, discovered checkpoints, and points of interest.

---

## Files

| File | Purpose |
|------|---------|
| `ui/data/level_map_data.gd` | Resource class holding map texture, world bounds, and POIs |
| `core/map_system/map_poi.gd` | Resource class for a single point of interest |
| `ui/map_display.gd` | The map overlay UI script |
| `ui/map_display.tscn` | The map overlay scene |
| `abilities/map/map_ability.gd` | Card ability that opens the map |
| `abilities/map/map_ability.tscn` | Card ability scene |
| `abilities/map/map.tres` | The Card resource for the map item |
| `core/map_system/map_reference_camera.gd` | @tool script for capturing reference screenshots |
| `core/map_system/map_reference_camera.tscn` | Reference camera scene (editor only, delete before shipping) |

---

## Setting Up a Map for a New Level

### 1. Create a LevelMapData resource

Right-click in the FileSystem dock → **New Resource** → search `LevelMapData`.

Save it somewhere like `level_mechanics/level_map_data/my_level_map_data.tres`.

Set these fields in the Inspector:

| Field | Description |
|-------|-------------|
| `Map Texture` | Your hand-drawn PNG |
| `Map Top Left` | XZ world position of the **top-left pixel** of the image |
| `Level Dimensions` | Width and height of the level in world units (XZ). Bottom-right = `map_top_left + level_dimensions` |
| `Points Of Interest` | Array of `MapPOI` resources (see below) |

### 2. Assign it to the Level

Select the root node of your level scene. In the Inspector, set **Current Map Data** to the `.tres` you just created.

---

## Capturing a Reference Screenshot

Use this to get a top-down reference image to trace over in Aseprite.

1. Open your level scene.
2. Add `core/map_system/map_reference_camera.tscn` as a child node.
3. In the Inspector, configure the node:

| Field | Value |
|-------|-------|
| `Map Top Left` | Same as your LevelMapData |
| `Level Dimensions` | Same as your LevelMapData |
| `Output Resolution` | Pixel size of the output image. Match the aspect ratio of your level (e.g. level is 120×56 units → use 1200×560 px) |
| `Output Path` | Where to save the PNG, e.g. `res://assets/ui/forest_reference.png` |

4. Click **📷 Save Reference PNG** in the Inspector. The file will appear in the FileSystem dock immediately.
5. **Delete or hide** this node before shipping — it does nothing in exported builds but adds unnecessary overhead.

---

## Drawing the Map in Aseprite

1. Open Aseprite. Create a new file at your chosen resolution.
2. Import the reference screenshot: **File → Open As New Layer** (or drag it in as a layer).
3. Reduce the reference layer opacity to ~40% and lock it.
4. Draw your stylized map on a new layer above it — trace walls, paths, open areas, landmarks.
5. When done, delete the reference layer and export the final PNG.
6. Assign the exported PNG to `Map Texture` in your `LevelMapData` resource.

Because `Map Top Left` and `Level Dimensions` are shared between the reference camera and the `LevelMapData`, coordinate mapping is pixel-perfect with no extra calibration.

---

## Adding Points of Interest

In your `LevelMapData` resource, click the **Points Of Interest** array and add entries. Each entry is a `MapPOI` resource:

| Field | Description |
|-------|-------------|
| `Label` | Text shown on hover (e.g. `"Shopkeeper"`) |
| `POI Type` | Enum: `GENERIC`, `SHOPKEEPER`, `BOSS`, `ITEM`, `EXIT`, `CAMPFIRE` |
| `Icon` | Texture2D shown on the map. Falls back to a white dot if unset |
| `World Position` | XZ world position of this POI |
| `Always Visible` | If true, always shown. If false, reserved for future discovery logic |

---

## Map Controls (In-Game)

| Input | Action |
|-------|--------|
| Mouse drag | Pan the map |
| Scroll wheel | Zoom in / out |
| Arrow keys | Pan the map |
| `+` / `-` | Zoom in / out |
| `E` or `Escape` | Close the map |

---

## How Coordinate Mapping Works

The `LevelMapData.world_to_pixel()` method converts any XZ world position to a pixel coordinate on the map image:

```gdscript
func world_to_pixel(world_xz: Vector2) -> Vector2:
    var t := (world_xz - map_top_left) / level_dimensions
    return t * Vector2(map_texture.get_width(), map_texture.get_height())
```

`t` is a 0–1 normalized position within the level bounds, then scaled to image pixels. This is used for the player marker, checkpoint dots, and POI icons.

---

## Checkpoint Markers

Discovered checkpoints are shown automatically as gold dots on the map. The map reads `SaveSystem.player_data.unlocked_checkpoints` filtered to the current level's `level_name`. No extra setup needed — checkpoints appear as the player discovers them.
