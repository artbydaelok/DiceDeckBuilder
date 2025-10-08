extends Area3D
class_name Hitbox

@export var damage = 0

signal on_hit

func _on_area_entered(area: Area3D) -> void:
	if area is Hurtbox:
		area.hurtbox_owner.apply_damage(damage as float)
	on_hit.emit()

func disable():
	for shape in get_children():
		shape.disabled = true
