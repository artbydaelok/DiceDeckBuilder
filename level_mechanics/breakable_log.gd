extends Node3D

@onready var broken_particles: GPUParticles3D = $BrokenParticles
@onready var mesh: Node3D = $tree_log_12

@onready var breakable_component: Node3D = $BreakableComponent

func _ready() -> void:
	breakable_component.broke.connect(on_broken)

# This function gets called from the axe object when it hits the hitbox
func on_broken():
	broken_particles.emitting = true
	broken_particles.reparent(GameEvents.current_level)
	queue_free()
