extends Node3D
var player

func _ready():
	player = get_tree().get_first_node_in_group("player")


func _process(delta):
	look_at(player.mesh.global_position)
	rotate_y(PI/2)
