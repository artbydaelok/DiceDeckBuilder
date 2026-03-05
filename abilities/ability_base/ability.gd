extends Node
class_name Ability

@onready var self_destroy_timer: Node = $SelfDestroyTimer

var entities_layer : Node3D
var player : Player


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	initialize()
	
func initialize():
	pass
	
func _process(delta: float) -> void:
	tick(delta)
	
func tick(delta):
	pass
