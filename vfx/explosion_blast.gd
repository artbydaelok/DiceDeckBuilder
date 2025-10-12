extends Node3D

@onready var debris: GPUParticles3D = $Debris
@onready var fire: GPUParticles3D = $Fire
@onready var smoke: GPUParticles3D = $Smoke

@onready var hitbox: Hitbox = $Hitbox

var is_player_attack : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_player_attack:
		hitbox.set_collision_mask_value(4, false)
		hitbox.set_collision_mask_value(5, true)
	hitbox.enable()
	debris.emitting = true
	fire.emitting = true
	smoke.emitting = true

	await get_tree().create_timer(0.1).timeout
	hitbox.disable()
	
	await get_tree().create_timer(2.0).timeout 
	
	queue_free()
