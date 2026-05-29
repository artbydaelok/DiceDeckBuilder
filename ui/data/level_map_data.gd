extends Resource
class_name LevelMapData

## The hand-drawn map image for this level.
@export var map_texture: Texture2D
## XZ world position corresponding to the top-left pixel of the map image.
@export var map_top_left: Vector2
## Width and height of the level in world units (XZ).
## Bottom-right world coord = map_top_left + level_dimensions.
@export var level_dimensions: Vector2
## Points of interest to display as icons on the map.
@export var points_of_interest: Array[MapPOI]


## Converts a 3D world position (XZ) to a pixel coordinate on the map image.
func world_to_pixel(world_xz: Vector2) -> Vector2:
	if level_dimensions == Vector2.ZERO or map_texture == null:
		return Vector2.ZERO
	var t := (world_xz - map_top_left) / level_dimensions
	return t * Vector2(map_texture.get_width(), map_texture.get_height())
