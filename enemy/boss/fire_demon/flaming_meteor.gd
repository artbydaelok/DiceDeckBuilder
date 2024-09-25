extends RigidBody3D

@onready var mesh: CSGSphere3D = $Mesh
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D
@onready var hitbox_collision: CollisionShape3D = %HitboxCollision

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	mesh.rotate(Vector3.FORWARD, PI * delta)

func _on_body_entered(body: Node) -> void:
	# Spawn/Trigger Explosion
	mesh.visible = false
	gpu_particles_3d.emitting = false
	await get_tree().create_timer(0.1).timeout
	hitbox_collision.disabled = true
	
	await get_tree().create_timer(2.0).timeout
	# Self Destroy
	queue_free()
