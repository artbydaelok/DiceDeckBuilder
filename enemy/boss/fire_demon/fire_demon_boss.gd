extends Enemy

# Meteors
const FLAMING_METEOR = preload("res://enemy/boss/fire_demon/flaming_meteor.tscn")

@export var meteor_parent_node : Node3D
var meteor_spawn_locations

# Fire Wall 
@onready var wall_spawn_anim: AnimationPlayer = $WallSpawnAnim
const FIRE_WALL = preload("res://enemy/boss/fire_demon/fire_wall.tscn")
@onready var fire_wall_spawn_right: Marker3D = $FireWallSpawnRight
@onready var fire_wall_spawn_left: Marker3D = $FireWallSpawnLeft

@onready var attack_timer: Timer = $AttackTimer

@onready var damage_animation: AnimationPlayer = $DamageAnimation

func initialize():
	meteor_spawn_locations = meteor_parent_node.get_children()
	
func spawn_walls(left_first: bool):
	if left_first:
		wall_spawn_anim.play("LeftFirst")
	else:
		wall_spawn_anim.play_backwards("LeftFirst")

func on_damage_taken(damage_amount):
	print(name + " has been hit for " + str(damage_amount) + " damage!")
	damage_animation.play("damaged")

func _on_attack_timer_timeout() -> void:
	attack_timer.wait_time = randf_range(4.0, 6.5)
	var choice = randi() % 2 == 0
	spawn_walls(choice)
	if (current_health / max_health) < 0.90:
		spawn_meteor()
		if (current_health / max_health) < 0.75:
			await get_tree().create_timer(0.75).timeout
			spawn_meteor()
		if (current_health / max_health) < 0.50:
			await get_tree().create_timer(0.5).timeout
			spawn_meteor()

func spawn_left_wall():
	var fire_wall = FIRE_WALL.instantiate()
	entities_layer.add_child(fire_wall)
	fire_wall.global_position = fire_wall_spawn_left.global_position

func spawn_right_wall():
	var fire_wall = FIRE_WALL.instantiate()
	entities_layer.add_child(fire_wall)
	fire_wall.global_position = fire_wall_spawn_right.global_position

func spawn_meteor():
	var spawn_position = meteor_spawn_locations.pick_random().global_position
	var meteor = FLAMING_METEOR.instantiate()
	var floor_indicator = FLOOR_INDICATOR.instantiate()
	entities_layer.add_child(floor_indicator)
	entities_layer.add_child(meteor)
	floor_indicator.global_position = spawn_position
	meteor.global_position = spawn_position + Vector3(0, 15, 0)

func spawn_center_fireball():
	pass
