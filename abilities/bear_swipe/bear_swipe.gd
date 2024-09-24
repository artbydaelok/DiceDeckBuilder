extends Ability

const BEAR_SWIPE_ANIMATION = preload("res://abilities/bear_swipe/bear_swipe_animation.tscn")
# Called when the node enters the scene tree for the first time.
func initialize():
	var bear_swipe = BEAR_SWIPE_ANIMATION.instantiate()
	get_tree().get_first_node_in_group("entities_layer").add_child(bear_swipe)
	bear_swipe.global_position = player.global_position + Vector3(0, 2.5, 0)
