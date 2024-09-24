extends Node3D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ArrowAnimation.play("DrawArrow")
	$AnimationPlayer.play("BowShoot")
	
	await $AnimationPlayer.animation_finished
	queue_free()
