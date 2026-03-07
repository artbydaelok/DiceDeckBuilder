extends Node3D

var player : Player

@export var offset : Vector3 = Vector3.ZERO

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	global_position = player.global_position + offset
