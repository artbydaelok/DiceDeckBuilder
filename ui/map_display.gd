extends Control

var player : Player
var map_top_left : Vector2 = Vector2(-104, -88)
var map_bottom_right : Vector2 = Vector2(26, 34)

@onready var player_marker: TextureRect = %PlayerMarker
@onready var player_marker_pivot: Control = %PlayerMarkerPivot

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	update_player_marker()

func _process(delta: float) -> void:
	#update_player_marker()
	pass

func update_player_marker():
	player_marker_pivot.position.x = remap(player.global_position.x, map_top_left.x, map_bottom_right.x, 0, 400)
	player_marker_pivot.position.y = remap(player.global_position.z, map_top_left.y, map_bottom_right.y, 0, 300)
