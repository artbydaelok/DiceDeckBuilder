extends Node3D

const EXPLOSIVE_BARREL = preload("res://enemy/boss/salt_and_pepper/explosive_barrel.tscn")

var entities_layer

var active: bool = false

@export var trigger_area : Area3D

var spawn_amount : int = 2
@onready var spawn_timer: Timer = $SpawnTimer
var _offsets_to_ignore : Dictionary

func _ready() -> void:
	entities_layer = get_tree().get_first_node_in_group("entities_layer")
	trigger_area.body_entered.connect(begin_attack)
	trigger_area.body_exited.connect(stop_attack)

func spawn_barrel():
	for i in range(spawn_amount):
		var random_offset : Vector3 = Vector3(randi_range(0,2) * 2, 0, randi_range(-2,1) * 2)
		print(random_offset)
		while _offsets_to_ignore.values().has(random_offset):
			random_offset = Vector3(randi_range(0,2) * 2, 0, randi_range(-2,1) * 2)
		
		
		var barrel = EXPLOSIVE_BARREL.instantiate()
		_offsets_to_ignore[barrel] = random_offset
		
		entities_layer.add_child(barrel)
		
		barrel.exploded.connect(allow_offset)
		
		barrel.global_position = global_position + random_offset
		print("Spawning Barrel")

func allow_offset(barrel_to_assess):
	_offsets_to_ignore.erase(barrel_to_assess)

func begin_attack(player):
	active = true
	if !spawn_timer.is_stopped():
		return
	
	print("Begin Attack")
	spawn_barrel()
	spawn_timer.start()

func stop_attack(player):
	active = false


func _on_spawn_timer_timeout() -> void:
	spawn_barrel()
	if active:
		spawn_timer.start()
