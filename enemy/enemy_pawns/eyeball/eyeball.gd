extends "res://enemy/enemy_pawns/grid_mover_base.gd"

@onready var hitbox: Hitbox = $Hitbox

# SHOULD REPOSITION PLAYER WHEN THEY ARE SEEN
@export var player_reposition_location_node : Marker3D

func on_initialize() -> void:
	hitbox.on_hit.connect(on_player_seen)
	
func on_player_seen():
	player.global_position = player_reposition_location_node.global_position
