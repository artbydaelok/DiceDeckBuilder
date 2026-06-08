extends Area3D
class_name Hitbox

@export var damage = 0

signal on_hit

func _on_area_entered(area: Area3D) -> void:
	if area is Hurtbox:
		var dmg := float(damage)
		var target = area.hurtbox_owner
		# A player attack landing on an enemy honors the player's one-shot
		# damage buff (Bear Swipe's Growl), then consumes it.
		if target is Enemy and dmg > 0.0:
			var p = get_tree().get_first_node_in_group("player")
			if p != null and "next_attack_damage_mult" in p and p.next_attack_damage_mult != 1.0:
				dmg *= p.next_attack_damage_mult
				# Deferred so every enemy hit in the SAME swing/blast gets the bonus
				# (a buffed AOE hits the whole group), then the buff clears.
				p.set_deferred("next_attack_damage_mult", 1.0)
		target.apply_damage(dmg)
	on_hit.emit()

func disable():
	for shape in get_children():
		shape.disabled = true

func enable():
	for shape in get_children():
		shape.disabled = false
