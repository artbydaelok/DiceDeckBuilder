extends Ability

const SHOTGUN_ANIMATION = preload("res://abilities/shotgun/shotgun_animation.tscn")

func initialize():
	var shotgun = SHOTGUN_ANIMATION.instantiate()
	entities_layer.add_child(shotgun)
	shotgun.global_position = player.global_position + Vector3(0, 3.5, 0)
