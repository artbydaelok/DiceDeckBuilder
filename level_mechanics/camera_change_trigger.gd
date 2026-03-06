extends Area3D

var camera : GameCamera

@export var relocation_node : Node3D
@export var one_shot : bool
## This makes the camera stop following the target. 
@export var static_cam : bool = false

func _ready() -> void:
	camera = get_tree().get_first_node_in_group("game_camera")
	area_entered.connect(_on_player_entered)

func _on_player_entered(body):
	var new_offset = relocation_node.global_position - global_position
	camera.relocate_to(relocation_node, new_offset)
	if static_cam:
		camera.follow_target = false
	else: 
		camera.follow_target = true
	if one_shot: queue_free()
	
