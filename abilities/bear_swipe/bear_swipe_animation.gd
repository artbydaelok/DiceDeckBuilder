extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_tree().get_first_node_in_group("player").x_grid_pos < 0:
		$SwipeTransform.play("swipe_left")
	else: 
		$SwipeTransform.play("swipe_right")
	
	$BearSwipe.get_node("AnimationPlayer").play("Swipe")
