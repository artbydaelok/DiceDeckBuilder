extends Enemy

@onready var wall_spawn_anim: AnimationPlayer = $WallSpawnAnim

func spawn_walls(left_first: bool):
	if left_first:
		wall_spawn_anim.play("left_first")
	else:
		wall_spawn_anim.play_backwards("left_first")

func on_damage_taken(damage_amount):
	print(name + " has been hit for " + str(damage_amount) + " damage!")
