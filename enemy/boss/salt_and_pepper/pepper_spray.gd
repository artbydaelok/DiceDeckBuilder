extends Node3D

@onready var pepper_anim: Sprite3D = $PepperAnim
const BULLET_PROJECTILE = preload("res://enemy/boss/salt_and_pepper/bullet_projectile.tscn")

func begin_attack():
	pepper_anim.play("show_guns")


func _on_pepper_anim_animation_finished() -> void:
	pass # Replace with function body.

func shoot(left_side: bool = false):
	pass

func begin_rotation():
	pepper_anim.rotate_y(PI/8)
