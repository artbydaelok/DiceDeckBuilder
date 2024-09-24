extends Node3D
class_name Enemy

var player : Player
var entities_layer : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	initialize()

func initialize():
	pass
