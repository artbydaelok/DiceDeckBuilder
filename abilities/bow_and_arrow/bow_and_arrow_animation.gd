extends Node3D

const ARROW_PROJECTILE = preload("res://abilities/bow_and_arrow/arrow_projectile.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ArrowAnimation.play("DrawArrow")
	$AnimationPlayer.play("BowShoot")
	
	await $AnimationPlayer.animation_finished
	queue_free()

func spawn_projectile():
	var arrow = ARROW_PROJECTILE.instantiate()
	get_tree().get_first_node_in_group("entities_layer").add_child(arrow)
	arrow.global_position = global_position
