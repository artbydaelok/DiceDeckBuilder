extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_timer: Timer = $AttackTimer

@export var is_green : bool = false

signal green_light
signal red_light

func _on_attack_timer_timeout() -> void:
	if not is_green:
		animation_player.play("green_light_attack")
		attack_timer.wait_time = animation_player.get_animation("green_light_attack").length
		attack_timer.start()
	if is_green:
		animation_player.play("RESET")
		attack_timer.wait_time = 8.0
		attack_timer.start()
		
# This function gets called in the animation player.
func change_to_green():
	is_green = true
	green_light.emit()
	
# This function gets called in the animation player.
func change_to_red():
	is_green = false
	red_light.emit()
