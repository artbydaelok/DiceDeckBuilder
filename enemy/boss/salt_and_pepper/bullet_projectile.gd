extends RigidBody3D
class_name BulletProjectile

@onready var blood_vfx_scene : PackedScene = preload("uid://2xohkxsgtdcj")
@export var hitbox: Hitbox

func setup(new_damage : int, is_player_owner: bool, spawn_position: Vector3, direction: Vector3, speed : float):
	# Sets Damage
	hitbox.damage = new_damage
	reset_hitbox_collisions()
	
	global_position = spawn_position
	
	# Sets Owner (Hitbox Collision Groups/Layers)
	if is_player_owner:
		hitbox.set_collision_layer_value(2, true) # Player Projectiles Layer
		hitbox.set_collision_mask_value(5, true) # Detects Enemy Hurtbox
	else: # If projectile is an enemy attack
		hitbox.set_collision_mask_value(4, true) # Detects Player Hurtbox
		hitbox.set_collision_layer_value(3, true) # Enemy Projectiles Layer
	
	# Sets Direction and Shoots
	shoot(direction, speed)

func shoot(direction: Vector3, speed: float):
	
	linear_velocity = direction * speed


func _on_self_destroy_timer_timeout() -> void:
	queue_free()


func reset_hitbox_collisions():
	hitbox.set_collision_mask_value(2, false) # Player Projectiles Layer
	hitbox.set_collision_layer_value(5, false) # Detects Enemy Hurtbox
	hitbox.set_collision_mask_value(4, false) # Enemy Projectiles Layer
	hitbox.set_collision_layer_value(3, false) # Detects Player Hurtbox

func _on_hitbox_on_hit() -> void:
	var bfx = blood_vfx_scene.instantiate()
	get_parent().add_child(bfx)
	bfx.global_position = global_position
	queue_free.call_deferred()
