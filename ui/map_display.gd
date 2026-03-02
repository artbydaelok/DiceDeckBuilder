extends Control

var player : Player

@onready var sub_viewport: SubViewport = %SubViewport
@onready var player_marker_pivot: Control = %PlayerMarkerPivot
@onready var map: TextureRect = %Map

var map_data : LevelMapData
var map_start : Vector2
var level_dimensions : Vector2 
var map_texture : Texture

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	# Gets the current map data
	map_data = GameEvents.current_level.current_map_data
	
	# Sets level dimensions to the measured dimensions of this level (Use Godot Ruler)
	level_dimensions  = map_data.level_dimensions
	
	# Sets the starting point (top left) of the map
	map_start = map_data.map_top_left
	
	# Sets the map texture
	map_texture = map_data.map_texture
	map.texture = map_texture
	
	# Sets the subviewport size to the image size
	sub_viewport.size = map_texture.get_size()
	
	update_player_marker()

func _process(delta: float) -> void:
	#update_player_marker()
	pass

func update_player_marker():
	var top_left_coord : Vector2 = map_start
	var bottom_right_coord : Vector2 = map_start + level_dimensions
	player_marker_pivot.position.x = remap(player.global_position.x, 
		top_left_coord.x, bottom_right_coord.x, 
		0, map_texture.get_width())
	player_marker_pivot.position.y = remap(player.global_position.z, 
		top_left_coord.y, bottom_right_coord.y, 
		0, map_texture.get_height())
