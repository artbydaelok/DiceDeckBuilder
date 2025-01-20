extends Node3D

const SALT_GRENADE = preload("res://enemy/boss/salt_and_pepper/salt_grenade.tscn")
@onready var spawn_timer: Timer = $SpawnTimer

@export var trigger_area : Area3D

var active : bool = false

var entities_layer

func _ready() -> void:
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	trigger_area.body_entered.connect(begin_attack)
	trigger_area.body_exited.connect(stop_attack)

func begin_attack(player):
	spawn_timer.start()
	active = true
	
func stop_attack(player):
	active = false

func spawn_grenade():
	var grenade = SALT_GRENADE.instantiate()
	entities_layer.add_child(grenade)
	grenade.global_position = global_position + Vector3(randi_range(-1, 1), 0, randi_range(-4, 4))

func _on_spawn_timer_timeout() -> void:
	spawn_grenade()
	if active:
		spawn_timer.start()
