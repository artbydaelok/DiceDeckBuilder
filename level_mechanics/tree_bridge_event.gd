extends Node3D

@onready var broken_particles: GPUParticles3D = $BrokenParticles
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var already_triggered : bool = false

func axe_hit():
	if already_triggered: return
	
	already_triggered = true
	
	broken_particles.emitting = true
	broken_particles.reparent(GameEvents.current_level)
	animation_player.play("break_down")
