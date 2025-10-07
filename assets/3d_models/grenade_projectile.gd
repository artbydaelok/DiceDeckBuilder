extends RigidBody3D

var player 

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	global_position = player.global_position + Vector3(0, 2, 0)
	linear_velocity = Vector3(0, 6.5, -5.5)
	angular_velocity = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI))
	await get_tree().create_timer(0.25).timeout 
	collision_shape.disabled = false
