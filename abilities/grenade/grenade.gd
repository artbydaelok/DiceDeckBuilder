extends Ability
## Grenade.
##   PRIMARY   (LMB / A) → lob a grenade with a fuse: big risky AoE.
##   SECONDARY (RMB / B) → C4: plant a charge at your feet (arms once you step away);
##                         press again to detonate it. Planting is gated/charged in
##                         CardSystem; detonating an existing charge is free.

const GRENADE_PROJECTILE = preload("uid://xfi6hatedmma")
const C4 = preload("res://abilities/grenade/c4.gd")


func initialize():
	if is_secondary:
		_c4_action()
		return

	# Primary: throw the grenade.
	var grenade = GRENADE_PROJECTILE.instantiate()
	grenade.player = player
	entities_layer.add_child(grenade)


## One charge at a time: detonate the planted C4 if there is one, otherwise plant one.
func _c4_action() -> void:
	if is_instance_valid(player.active_c4):
		player.active_c4.detonate()
		return
	var c4 = C4.new()
	c4.setup(player)
	entities_layer.add_child(c4)
	c4.global_position = Vector3(player.global_position.x, 0.0, player.global_position.z)
	player.active_c4 = c4
