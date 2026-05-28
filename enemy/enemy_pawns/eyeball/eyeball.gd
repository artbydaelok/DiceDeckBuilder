extends Enemy

@onready var hitbox: Hitbox = $Hitbox

@export var player_reposition_location_node: Marker3D


func initialize() -> void:
	hitbox.on_hit.connect(on_player_seen)


func on_player_seen():
	player.global_position = player_reposition_location_node.global_position
