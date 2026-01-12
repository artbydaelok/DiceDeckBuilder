extends StaticBody3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

func disable_collision():
	collision_shape_3d.disabled = true
	
func enable_collision():
	collision_shape_3d.disabled = false
	
