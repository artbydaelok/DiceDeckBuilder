extends RigidBody3D

func shoot(direction: Vector3, speed: float):
	linear_velocity = direction * speed


func _on_self_destroy_timer_timeout() -> void:
	queue_free()


func _on_hitbox_on_hit() -> void:
	queue_free()
