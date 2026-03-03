extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Hitbox = $Hitbox
@onready var caught_sfx: AudioStreamPlayer3D = $CaughtSFX
@onready var close_sfx: AudioStreamPlayer3D = $CloseSFX
@onready var activate_sfx: AudioStreamPlayer3D = $ActivateSFX

@onready var visuals: Node3D = $BearTrapRig

var has_caught : bool = false

func _ready() -> void:
	hitbox.on_hit.connect(_on_hit)
	trigger()

func _on_hit():
	has_caught = true
	hitbox.queue_free()
	caught_sfx.play()
	trigger()
	
	await get_tree().create_timer(5.0).timeout
	
	var tween := create_tween()
	tween.tween_property(visuals, "scale", Vector3.ZERO, 1.5)
	await tween.finished
	queue_free()

func trigger():
	close_sfx.play()
	animation_player.play("Trigger")

func activate():
	animation_player.play_backwards("Trigger")
	var tween := create_tween()
	var initial_position := global_position
	
	activate_sfx.play()
	
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", initial_position + Vector3(0, 1.5, 0), 0.25)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", initial_position + Vector3(0, -2, 0), 0.25)
