extends Node3D

@onready var blood_particles: GPUParticles3D = $BloodParticles

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blood_particles.emitting = true
