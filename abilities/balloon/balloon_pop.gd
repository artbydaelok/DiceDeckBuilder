extends Ability

const BALLOON_POP_ANIMATION = preload("res://abilities/balloon/balloon_pop_animation.tscn")

func initialize():
	var balloon = BALLOON_POP_ANIMATION.instantiate()
	entities_layer.add_child(balloon)
	balloon.global_position = player.global_position + Vector3(0, 2, 0)
