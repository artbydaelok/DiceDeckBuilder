extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ground_scale_anim: TweenProperty = $Ground/GroundScaleAnim

const FOREST_LEVEL_DIALOGUE = preload("uid://ha3t3hrgxnfs")

@onready var block_collision: CollisionShape3D = %BlockCollision

func _ready() -> void:
	visible = false

func appear():
	visible = true
	ground_scale_anim.play()
	animation_player.play("appear")

# This function gets called from the axe object when it hits the hitbox
func axe_hit():
	DialogueManager.show_dialogue_balloon(FOREST_LEVEL_DIALOGUE, "mother_nature_1")

func disappear():
	ground_scale_anim.play()
	animation_player.play_backwards("appear")
	block_collision.disabled = true
