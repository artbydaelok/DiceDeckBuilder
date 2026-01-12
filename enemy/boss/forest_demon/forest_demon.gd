extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ground_scale_anim: TweenProperty = $Ground/GroundScaleAnim

func _ready() -> void:
	visible = false

func appear():
	visible = true
	ground_scale_anim.play()
	animation_player.play("appear")
