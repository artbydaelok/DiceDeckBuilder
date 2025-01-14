extends Node
class_name Ability

var entities_layer : Node3D
var player 

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	initialize()
	
func initialize():
	pass
