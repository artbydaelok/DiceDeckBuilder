extends Vehicle
class_name MovingPlatform

## Crash Bandicoot-style moving platform.
## Ping-pongs between two Marker3D waypoints, pausing at each end
## for stop_duration seconds. The platform is only boardable during a stop.

## The two endpoints. Place these as Marker3D nodes in the level and assign them.
@export var point_a: Marker3D
@export var point_b: Marker3D

## How long the platform takes to travel between the two points.
@export var travel_duration: float = 2.0

## How long the platform waits at each end (the boarding window).
@export var stop_duration: float = 1.5

## Easing for the travel tween.
@export_enum("Linear", "Sine", "Bounce", "Spring") var ease_type: int = 1

## If true, the platform starts moving immediately on _ready.
## If false, call start() manually.
@export var autostart: bool = true


enum State { STOPPED_AT_A, TRAVELING_TO_B, STOPPED_AT_B, TRAVELING_TO_A }

var _state: State = State.STOPPED_AT_A
var _stop_timer: float = 0.0
var _traveling: bool = false


# ── Vehicle hooks ────────────────────────────────────────────────────────────

func vehicle_ready() -> void:
	if point_a == null:
		push_warning("MovingPlatform '%s': point_a not assigned." % name)
		return
	global_position = point_a.global_position
	if autostart:
		_begin_stop(State.STOPPED_AT_A)


func vehicle_process(delta: float) -> void:
	match _state:
		State.STOPPED_AT_A, State.STOPPED_AT_B:
			_stop_timer -= delta
			if _stop_timer <= 0.0:
				_depart()


# ── Movement ─────────────────────────────────────────────────────────────────

func start() -> void:
	_begin_stop(State.STOPPED_AT_A)


func _begin_stop(stop_state: State) -> void:
	_state = stop_state
	_stop_timer = stop_duration
	is_boardable = true


func _depart() -> void:
	is_boardable = false
	if _state == State.STOPPED_AT_A:
		_travel_to(point_b, State.TRAVELING_TO_B, State.STOPPED_AT_B)
	else:
		_travel_to(point_a, State.TRAVELING_TO_A, State.STOPPED_AT_A)


func _travel_to(target: Marker3D, traveling_state: State, arrival_state: State) -> void:
	if target == null: return
	_state = traveling_state

	var trans_options: Array[Tween.TransitionType] = [
		Tween.TRANS_LINEAR,
		Tween.TRANS_SINE,
		Tween.TRANS_BOUNCE,
		Tween.TRANS_SPRING,
	]
	var trans: Tween.TransitionType = trans_options[ease_type]

	var tween := create_tween()
	tween.tween_property(self, "global_position", target.global_position, travel_duration) \
		.set_ease(Tween.EASE_IN_OUT) \
		.set_trans(trans)
	tween.tween_callback(func(): _begin_stop(arrival_state))


# ── Overridable hooks ────────────────────────────────────────────────────────

func on_player_boarded(player: Player) -> void:
	pass  # Override for reactions (e.g. play a creak sound, animate)


func on_player_disembarked(player: Player) -> void:
	pass
