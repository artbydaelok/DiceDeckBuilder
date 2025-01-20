extends RigidBody3D

const EXPLOSION_BLAST = preload("res://vfx/explosion_blast.tscn")

@onready var bounce_sfx: AudioStreamPlayer = $BounceSFX

func _on_body_entered(body: Node) -> void:
	bounce_sfx.play()
	await get_tree().create_timer(0.8).timeout
	explode()

func explode():
	# Spawn VFX and Hitbox
	var blast = EXPLOSION_BLAST.instantiate()
	get_tree().get_first_node_in_group("entities_layer").add_child(blast)
	blast.global_position = global_position
	# Destroy Grenade
	queue_free()
