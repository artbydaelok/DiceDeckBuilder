extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	linear_velocity = Vector3(0, 0, -80)
	
#TODO: Add "MISS" text if the player hits the imaginary back wall that indicates player missed the target/boss
func on_miss():
	pass

func _on_hitbox_area_entered(area: Area3D) -> void:
	linear_velocity = Vector3.ZERO
	gravity_scale = 0
	
	$ArrowHitSFX.play()
	
	await get_tree().create_timer(0.35).timeout
	queue_free()


func _on_self_destruct_timeout() -> void:
	queue_free()
