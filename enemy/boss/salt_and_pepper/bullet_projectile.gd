extends RigidBody3D

@onready var blood_vfx_scene : PackedScene = preload("uid://2xohkxsgtdcj")	

func shoot(direction: Vector3, speed: float):
	linear_velocity = direction * speed


func _on_self_destroy_timer_timeout() -> void:
	queue_free()


func _on_hitbox_on_hit() -> void:
	var bfx = blood_vfx_scene.instantiate()
	get_parent().add_child(bfx)
	bfx.global_position = global_position
	queue_free.call_deferred()
