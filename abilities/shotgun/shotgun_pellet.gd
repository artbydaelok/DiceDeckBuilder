extends RigidBody3D

@onready var blood_vfx_scene : PackedScene = preload("uid://2xohkxsgtdcj")	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_tree().get_first_node_in_group("player").y_grid_pos > 0:
		$Hitbox.damage = 1
		
	linear_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), -50)


func _on_hitbox_on_hit() -> void:
	var bfx = blood_vfx_scene.instantiate()
	get_parent().add_child(bfx)
	bfx.global_position = global_position
	queue_free.call_deferred()
