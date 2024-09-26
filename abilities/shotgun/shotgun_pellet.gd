extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_tree().get_first_node_in_group("player").y_grid_pos > 0:
		$Hitbox.damage = 1
		
	linear_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), -50)
