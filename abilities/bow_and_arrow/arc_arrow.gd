extends Node3D
## A single arrow that flies a fixed parabolic arc from `from` to a target tile,
## oriented along its flight, damaging enemies/breakables and sticking on impact.
## Used by the Bow's SECONDARY volley. Build with .new(), call setup(), then add it.

const HITBOX_SCENE := preload("res://core/components/hitbox.tscn")
const ARROW_MODEL := preload("res://abilities/bow_and_arrow/Arrow.glb")

const ARC_HEIGHT := 4.0      # peak height of the lob
const FLIGHT_TIME := 0.6
const STUCK_TIME := 0.4
const ARROW_SCALE := 0.5

var damage := 5

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _stuck := false
var _tween: Tween
var _visual: Node3D
var _hitbox: Hitbox
var _prev := Vector3.ZERO


## Set the launch point, landing point, and damage before adding to the tree.
func setup(from: Vector3, to: Vector3, dmg: int) -> void:
	_from = from
	_to = to
	damage = dmg


func _ready() -> void:
	global_position = _from
	_prev = _from

	_visual = ARROW_MODEL.instantiate()
	add_child(_visual)

	_hitbox = HITBOX_SCENE.instantiate()
	_hitbox.damage = damage
	_hitbox.collision_mask = 48  # EnemyHurtbox (layer 5) + Breakable (layer 6)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1, 1, 1)
	shape.shape = box
	_hitbox.add_child(shape)
	_hitbox.area_entered.connect(_on_hit)
	add_child(_hitbox)

	_tween = create_tween()
	_tween.tween_method(_fly, 0.0, 1.0, FLIGHT_TIME)
	_tween.tween_callback(_stick)


func _fly(p: float) -> void:
	var flat := _from.lerp(_to, p)
	var pos := flat + Vector3.UP * ARC_HEIGHT * sin(p * PI)
	global_position = pos
	_orient(pos - _prev)
	_prev = pos


## Point the arrow so its head leads along the flight direction. Arrow.glb's head
## points down its local -X, so local +X maps to -dir.
func _orient(dir: Vector3) -> void:
	if not is_instance_valid(_visual) or dir.length() < 0.0001:
		return
	var x := -dir.normalized()
	var up_ref := Vector3.UP if absf(x.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	var z := x.cross(up_ref).normalized()
	var y := z.cross(x).normalized()
	_visual.global_transform = Transform3D(Basis(x, y, z).scaled(Vector3.ONE * ARROW_SCALE), global_position)


func _on_hit(area: Area3D) -> void:
	if _stuck:
		return
	var target := area.get_parent()
	if target and target.has_method("axe_hit"):
		target.axe_hit()
	_stick()


func _stick() -> void:
	if _stuck:
		return
	_stuck = true
	if _tween and _tween.is_valid():
		_tween.kill()
	if is_instance_valid(_hitbox):
		_hitbox.set_deferred("monitoring", false)   # landed → stop dealing damage
	await get_tree().create_timer(STUCK_TIME).timeout
	queue_free()
