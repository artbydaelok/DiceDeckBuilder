extends Enemy

@onready var salt_sprite: AnimatedSprite3D = $SaltSprite
@onready var pepper_sprite: AnimatedSprite3D = $PepperSprite

@export var traffic_light : Node3D

func salt_grenade_attack():
	salt_sprite.play("throw_bombs")

func stop_salt_grenades():
	salt_sprite.play("default")


func _on_pepper_sprite_animation_finished() -> void:
	if pepper_sprite.animation == "show_guns":
		pepper_sprite.play("shoot")
