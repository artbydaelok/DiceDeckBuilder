extends Area3D
class_name Hitbox

@export var damage = 0


func _on_area_entered(area: Area3D) -> void:
	area.hurtbox_owner.apply_damage(damage as float)