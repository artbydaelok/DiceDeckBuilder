extends Node3D
class_name Enemy

const FLOOR_INDICATOR = preload("res://enemy/boss/floor_indicator.tscn")
const END_SCREEN = preload("res://menus/end_screen.tscn")

@export var user_interface : CanvasLayer
const CENTER_WARNING_SIGN = preload("res://ui/center_warning_sign.tscn")

@export var max_health = 100
var current_health
signal health_updated(health_change, new_current_health)
signal died

var player : Node
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
	
	if current_health < 0:
		died.emit()
		on_died()
		
		var c = CENTER_WARNING_SIGN.instantiate()
		user_interface.add_child(c)
		c.setup_and_play("BOSS DEFEATED!")
		c.menu_return = true

		#queue_free()  
	
func on_damage_taken(damage_amount):
	pass

func on_died():
	pass
