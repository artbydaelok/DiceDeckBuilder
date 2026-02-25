extends Node3D

@export var disabled := false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	if disabled or GameEvents.is_checkpoint_transfer: return
	reposition_player()
	
func reposition_player():
	get_tree().get_first_node_in_group("player").global_position = global_position
