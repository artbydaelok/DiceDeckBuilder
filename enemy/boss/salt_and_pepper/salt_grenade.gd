extends RigidBody3D

const EXPLOSION_BLAST = preload("res://vfx/explosion_blast.tscn")

@onready var grenade_mesh: MeshInstance3D = $GrenadeMesh

@onready var bounce_sfx: AudioStreamPlayer = $BounceSFX
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var random_rotation_axis : Vector3
var random_rotation_speed : float

func _ready() -> void:
	random_rotation_axis = (Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))).normalized()
	random_rotation_speed = randf_range(0.2, TAU)

func _process(delta: float) -> void:
	grenade_mesh.rotate(random_rotation_axis, random_rotation_speed * delta)

func _on_body_entered(body: Node) -> void:
	bounce_sfx.play()
	animation_player.play("warning_flash")
	await get_tree().create_timer(0.8).timeout
	explode()

func explode():
	# Spawn VFX and Hitbox
	var blast = EXPLOSION_BLAST.instantiate()
	get_tree().get_first_node_in_group("entities_layer").add_child(blast)
	blast.global_position = global_position
	# Destroy Grenade
	queue_free()
