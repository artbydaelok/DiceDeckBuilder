extends Ability

const GRENADE_PROJECTILE = preload("uid://xfi6hatedmma")

func initialize():
	var grenade = GRENADE_PROJECTILE.instantiate()
	grenade.player = player
	entities_layer.add_child(grenade)
