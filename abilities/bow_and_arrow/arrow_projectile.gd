extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	linear_velocity = Vector3(0, 0, -80)


func _on_hitbox_area_entered(area: Area3D) -> void:
	linear_velocity = Vector3.ZERO
	gravity_scale = 0
	
	$ArrowHitSFX.play()
	
	await get_tree().create_timer(0.35).timeout
	queue_free()
