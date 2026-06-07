extends RigidBody3D
## Straight-shot arrow. Speed and damage scale with the bow's charge; a fully-drawn
## shot crits. `charge` (seconds held) is set by the bow before this enters the tree.

var charge: float = 0.0

const BASE_SPEED := 45.0
const FULL_SPEED := 90.0
const FULL_CHARGE := 1.0       # seconds of charge for a full-power shot
const BASE_DAMAGE := 4
const FULL_DAMAGE := 8
const CRIT_DAMAGE := 16


func _ready() -> void:
	var t := clampf(charge / FULL_CHARGE, 0.0, 1.0)
	linear_velocity = Vector3(0, 0, -lerpf(BASE_SPEED, FULL_SPEED, t))

	var dmg := int(roundf(lerpf(float(BASE_DAMAGE), float(FULL_DAMAGE), t)))
	if charge >= FULL_CHARGE:   # fully drawn = critical hit
		dmg = CRIT_DAMAGE
	$Hitbox.damage = dmg


#TODO: Add "MISS" text if the player hits the imaginary back wall.
func on_miss():
	pass


func _on_hitbox_area_entered(area: Area3D) -> void:
	linear_velocity = Vector3.ZERO
	gravity_scale = 0
	$ArrowHitSFX.play()
	await get_tree().create_timer(0.35).timeout
	queue_free()


func _on_self_destruct_timeout() -> void:
	queue_free()
