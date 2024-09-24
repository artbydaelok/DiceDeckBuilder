extends Ability

const AXE_THROW = preload("res://abilities/axe_throw/axe_projectile.tscn")

func initialize():
	var axe = AXE_THROW.instantiate()
	axe.player = player
	entities_layer.add_child(axe)
