extends Enemy

@onready var salt_sprite: AnimatedSprite3D = $SaltSprite
@onready var pepper_sprite: AnimatedSprite3D = $PepperSprite

@onready var pepper_animations: AnimationPlayer = $PepperAnimations

@export var traffic_light : Node3D
@export var pepper_spray: Node3D

func salt_grenade_attack():
	salt_sprite.play("throw_bombs")

func stop_salt_grenades():
	salt_sprite.play("default")


func _on_pepper_animations_animation_finished(anim_name: StringName) -> void:
	pass # Replace with function body.
