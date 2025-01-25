extends Node3D

const SALT_GRENADE = preload("res://enemy/boss/salt_and_pepper/salt_grenade.tscn")
@onready var spawn_timer: Timer = $SpawnTimer

@export var trigger_area : Area3D

var active : bool = false

var entities_layer

@export var traffic_light : Node3D
@export var boss : Node3D

func _ready() -> void:
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	trigger_area.body_entered.connect(set_active)
	trigger_area.body_exited.connect(remove_active)
	
	traffic_light.red_light.connect(begin_attack)
	traffic_light.green_light.connect(stop_attack)

# When the player enters Salt's side, we set active to true so that when the red light comes, it is triggered.
func set_active(player):
	active = true

# When the player exits Salt's side, we set active to false so that when the red light comes, it is not triggered.
func remove_active(player):
	active = false

# If player is on Salt's side, this function will begin spawning grenades until green light happens. 
func begin_attack():
	if active:
		spawn_timer.start()
		boss.salt_grenade_attack()

# Regardless of whether this attack is happening, this prevents from happening further.
func stop_attack():
	spawn_timer.stop()
	boss.stop_salt_grenades()

# This instantiates grenades randomly above the arena. 
func spawn_grenade():
	var grenade = SALT_GRENADE.instantiate()
	entities_layer.add_child(grenade)
	grenade.global_position = global_position + Vector3(randi_range(-2, 2) * 2, 0, randi_range(-2, 2) * 2)

func _on_spawn_timer_timeout() -> void:
	spawn_grenade()
