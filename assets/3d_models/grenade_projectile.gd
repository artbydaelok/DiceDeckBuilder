extends RigidBody3D

var player 

const EXPLOSION_BLAST = preload("res://vfx/explosion_blast.tscn")

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var grenade_mesh: Node3D = $Grenade
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var radius_marker: Sprite3D = $RadiusMarker

var random_rotation_axis : Vector3
var random_rotation_speed : float

func _ready() -> void:
	random_rotation_axis = (Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))).normalized()
	random_rotation_speed = randf_range(0.2, TAU)
	radius_marker.reparent(get_tree().get_first_node_in_group("entities_layer"))
	global_position = player.global_position + Vector3(0, 2, 0)
	linear_velocity = Vector3(0, 5.5, -4.0)
	angular_velocity = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI))
	await get_tree().create_timer(0.25).timeout 
	collision_shape.disabled = false
	
func _process(delta: float) -> void:
	grenade_mesh.rotate(random_rotation_axis, random_rotation_speed * delta)
	if ray_cast_3d.is_colliding():
		radius_marker.global_position = ray_cast_3d.get_collision_point() + Vector3(0, 0.5, 0)
		radius_marker.visible = true
		var r = global_position.distance_to(radius_marker.global_position) * 0.1
		r = 1 - clamp(r, 0.0, 1.0)
		radius_marker.material_override.set_shader_parameter("radius", r)


func _on_explode_timer_timeout() -> void:
	explode()

func explode():
	# Spawn VFX and Hitbox
	var blast = EXPLOSION_BLAST.instantiate()
	blast.is_player_attack = true
	get_tree().get_first_node_in_group("entities_layer").add_child(blast)
	blast.global_position = global_position
	radius_marker.queue_free()
	# Destroy Grenade
	queue_free()
