extends Enemy

@onready var wall_spawn_anim: AnimationPlayer = $WallSpawnAnim
const FIRE_WALL = preload("res://enemy/boss/fire_demon/fire_wall.tscn")
@onready var fire_wall_spawn_right: Marker3D = $FireWallSpawnRight
@onready var fire_wall_spawn_left: Marker3D = $FireWallSpawnLeft

func spawn_walls(left_first: bool):
	if left_first:
		wall_spawn_anim.play("LeftFirst")
	else:
		wall_spawn_anim.play_backwards("LeftFirst")

func on_damage_taken(damage_amount):
	print(name + " has been hit for " + str(damage_amount) + " damage!")


func _on_attack_timer_timeout() -> void:
	spawn_walls(true)

func spawn_left_wall():
	var fire_wall = FIRE_WALL.instantiate()
	entities_layer.add_child(fire_wall)
	fire_wall.global_position = fire_wall_spawn_left.global_position

func spawn_right_wall():
	var fire_wall = FIRE_WALL.instantiate()
	entities_layer.add_child(fire_wall)
	fire_wall.global_position = fire_wall_spawn_right.global_position

func spawn_center_fireball():
	pass
