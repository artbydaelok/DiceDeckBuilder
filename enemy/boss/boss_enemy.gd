extends Node3D
class_name Enemy

@export var max_health = 100
var current_health
signal health_updated(health_change, new_current_health)

var player : Player
var entities_layer : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	initialize()

func initialize():
	pass

func apply_damage(damage_amount):
	current_health -= damage_amount
	health_updated.emit(damage_amount, current_health)
	on_damage_taken(damage_amount)
	
func on_damage_taken(damage_amount):
	pass
