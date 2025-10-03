extends RigidBody3D

const EXPLOSION_BLAST = preload("res://vfx/explosion_blast.tscn")

@onready var grenade_mesh: MeshInstance3D = $GrenadeMesh

@onready var bounce_sfx: AudioStreamPlayer = $BounceSFX
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var random_rotation_axis : Vector3
var random_rotation_speed : float

var bounced : bool = false

@onready var radius_marker: Sprite3D = $RadiusMarker
@onready var ray_cast_3d: RayCast3D = $RayCast3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	random_rotation_axis = (Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))).normalized()
	random_rotation_speed = randf_range(0.2, TAU)
	radius_marker.reparent(get_tree().get_first_node_in_group("entities_layer"))
	

func _process(delta: float) -> void: 
	grenade_mesh.rotate(random_rotation_axis, random_rotation_speed * delta)
	if ray_cast_3d.is_colliding():
		radius_marker.global_position = ray_cast_3d.get_collision_point() + Vector3(0, 0.5, 0)
		radius_marker.visible = true
		var r = global_position.distance_to(radius_marker.global_position) * 0.1
		r = 1 - clamp(r, 0.0, 1.0)
		if not bounced:
			radius_marker.material_override.set_shader_parameter("radius", r)
		

func _on_body_entered(body: Node) -> void:
	bounce_sfx.play()
	bounced = true
	var f = func(): collision_shape_3d.disabled = true
	f.call_deferred()
	animation_player.play("warning_flash")
	await get_tree().create_timer(0.8).timeout
	explode()

func explode():
	# Spawn VFX and Hitbox
	var blast = EXPLOSION_BLAST.instantiate()
	get_tree().get_first_node_in_group("entities_layer").add_child(blast)
	blast.global_position = global_position
	radius_marker.queue_free()
	# Destroy Grenade
	queue_free()
