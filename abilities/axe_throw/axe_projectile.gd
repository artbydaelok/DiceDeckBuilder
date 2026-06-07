extends Node3D
## Deterministic thrown axe — a fixed parabolic arc, no physics / RigidBody.
## Always the same trajectory: launches above the player, arcs OVER the adjacent
## tile, and comes down ~2–3 tiles ahead, tumbling. Sticks on hit or on landing.

@onready var axe_root: Node3D = $AxeRoot
@onready var hitbox_shape: CollisionShape3D = %HitboxShape

var player

# ── Trajectory (all deterministic; tune to taste) ──
const FORWARD_DISTANCE := 6.0   # how far it travels in −Z (~2.5 tiles)
const ARC_HEIGHT := 3.0         # peak height above the launch point
const FLIGHT_TIME := 0.45
const START_HEIGHT := 2.0       # launch height above the player
const LAND_HEIGHT := 0.6        # height it comes down to at the end
const SPIN_SPEED := -PI * 6.0   # rad/s tumble (about the axe's right axis)
const STUCK_TIME := 0.35        # how long it stays embedded before despawning

var _stuck := false
var _start: Vector3
var _end: Vector3
var _flight_tween: Tween


func _ready() -> void:
	_start = player.global_position + Vector3(0, START_HEIGHT, 0)
	_end = player.global_position + Vector3(0, LAND_HEIGHT, -FORWARD_DISTANCE)
	global_position = _start
	hitbox_shape.disabled = false

	_flight_tween = create_tween()
	_flight_tween.tween_method(_arc, 0.0, 1.0, FLIGHT_TIME)
	_flight_tween.tween_callback(_on_landed)


## Parabolic interpolation: straight line from start to end, plus a sine bump.
func _arc(p: float) -> void:
	var flat := _start.lerp(_end, p)
	global_position = flat + Vector3.UP * ARC_HEIGHT * sin(p * PI)


func _process(delta: float) -> void:
	if not _stuck:
		axe_root.rotate(Vector3.RIGHT, SPIN_SPEED * delta)


## Reached the end without hitting anything — stick at the landing spot.
func _on_landed() -> void:
	_stick()


## Connected with an enemy/obstacle mid-flight.
func _on_hitbox_area_entered(area: Area3D) -> void:
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
	if _flight_tween and _flight_tween.is_valid():
		_flight_tween.kill()  # stop moving along the arc
	# Deferred: we may be inside a physics query flush (the area_entered callback).
	hitbox_shape.set_deferred("disabled", true)
	if has_node("AxeHitSFX"):
		$AxeHitSFX.play()
	await get_tree().create_timer(STUCK_TIME).timeout
	queue_free()
