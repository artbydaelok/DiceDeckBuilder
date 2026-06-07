extends Node3D

const ARROW_PROJECTILE = preload("res://abilities/bow_and_arrow/arrow_projectile.tscn")

## Charge seconds at which the bow is fully drawn. (Match the arrow's FULL_CHARGE.)
const FULL_DRAW_TIME := 1.0
## Animation time of the fully-drawn pose. The loose (spawn_projectile method track)
## is at 0.8s, so the drawn pose is just before it. Tune to taste.
const DRAW_END_TIME := 0.7

## Charge seconds, set by the bow ability before this enters the tree.
var charge: float = 0.0
## True while the player is holding the draw; release() looses the arrow.
var charging: bool = false


func _ready() -> void:
	$ArrowAnimation.play("DrawArrow")
	$AnimationPlayer.play("BowShoot")

	if charging:
		# Drive the draw position manually from the charge (speed 0 = no auto-advance).
		$ArrowAnimation.speed_scale = 0.0
		$AnimationPlayer.speed_scale = 0.0
		set_draw(0.0)
	else:
		await $AnimationPlayer.animation_finished
		queue_free()


## Map charge seconds → draw pose. Called each frame while charging, so the draw
## tracks the charge instead of the AnimationPlayer's own clock.
func set_draw(seconds: float) -> void:
	var t := clampf(seconds / FULL_DRAW_TIME, 0.0, 1.0)
	var pos := t * DRAW_END_TIME
	$ArrowAnimation.seek(pos, true)
	$AnimationPlayer.seek(pos, true)


## Resume from the held draw pose at normal speed → crosses the loose → fires.
func release() -> void:
	charging = false
	$ArrowAnimation.speed_scale = 1.0
	$AnimationPlayer.speed_scale = 1.0
	await $ArrowAnimation.animation_finished
	queue_free()


func spawn_projectile():
	var arrow = ARROW_PROJECTILE.instantiate()
	get_tree().get_first_node_in_group("entities_layer").add_child(arrow)
	arrow.global_position = global_position
	if "charge" in arrow:
		arrow.charge = charge
