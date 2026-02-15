extends Node3D

@onready var broken_particles: GPUParticles3D = $BrokenParticles
@onready var mesh: Node3D = $tree_log_12
@onready var static_body_3d: StaticBody3D = $StaticBody3D

# This function gets called from the axe object when it hits the hitbox
func axe_hit():
	broken_particles.emitting = true
	broken_particles.reparent(GameEvents.current_level)
	queue_free()
