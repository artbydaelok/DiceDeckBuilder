extends Node
class_name GridMoverComponent

## GridMoverComponent
##
## Handles grid-based movement for any Node3D — enemies, props, platforms, anything.
## Add as a child node and assign target in the inspector (defaults to parent if left empty).
##
## Connect step_started / step_finished signals to drive animations externally:
##   grid_mover.step_started.connect(func(dir): animation_player.play("walk"))
##   grid_mover.step_finished.connect(func(dir): animation_player.play("idle"))
##
## Call move(direction) directly to trigger a single step from code.

enum Direction { FORWARD, BACK, LEFT, RIGHT }

const DIRECTION_MAP = {
	Direction.FORWARD: Vector3.FORWARD,
	Direction.BACK:    Vector3.BACK,
	Direction.LEFT:    Vector3.LEFT,
	Direction.RIGHT:   Vector3.RIGHT,
}

const DIRECTION_OPPOSITE = {
	Direction.FORWARD: Direction.BACK,
	Direction.BACK:    Direction.FORWARD,
	Direction.LEFT:    Direction.RIGHT,
	Direction.RIGHT:   Direction.LEFT,
}

## The Node3D to move. If left empty, defaults to the parent node.
@export var target: Node3D

@export_category("Movement")
@export var cell_size: float = 2.0
@export var move_speed: float = 4.0

@export_category("Pattern")
## Sequence of directions the mover cycles through. Each entry is a compass direction.
@export var pattern: Array[Direction] = []
@export var ping_pong_pattern: bool = false
## If true, follows the player's movement direction instead of the pattern.
@export var chase_player: bool = false

@export_category("Trigger")
## If true, moves once each time the player moves. If false, uses the interval timer.
@export var react_to_player_move: bool = false
@export var interval_time: float = 0.75
## If false, the timer won't start until start() is called. Useful when you need to
## configure the pattern from code in initialize() before movement begins.
@export var autostart: bool = true

@export_category("Rotation")
## Rotate the target to face the direction of each step.
@export var rotate_to_face_direction: bool = false

@export_category("Audio")
## Optional. If assigned, this player is played at the START of each step (e.g. a
## footstep / slide sound). Leave empty to stay silent. For anything more involved
## (per-direction sounds, pitch variation), connect step_started / step_finished instead.
@export var move_sfx: AudioStreamPlayer3D

## Emitted the moment a step begins. Useful for starting walk/jump animations.
signal step_started(direction: Vector3)
## Emitted when the tween finishes and the target has reached the new cell.
signal step_finished(direction: Vector3)

var moving: bool = false
var _step: int = 0
var _player: Node3D
var _timer: Timer


func _ready() -> void:
	if target == null:
		target = get_parent() as Node3D

	_player = get_tree().get_first_node_in_group("player")

	if react_to_player_move:
		if _player and _player.has_signal("player_moved"):
			_player.player_moved.connect(_on_player_moved)
	else:
		_timer = Timer.new()
		_timer.wait_time = interval_time
		_timer.one_shot = false
		_timer.timeout.connect(_on_timer_timeout)
		add_child(_timer)
		if autostart:
			_timer.start()


## Start the interval timer. Call this from initialize() when autostart is false.
## Also re-applies interval_time in case it was changed after _ready().
func start() -> void:
	if _timer:
		_timer.wait_time = interval_time
		_timer.start()


## Convenience method: fill the pattern with `steps` repetitions of `dir`.
## Optionally enables ping_pong. Resets the step counter.
func set_linear_pattern(dir: Direction, steps: int, ping_pong: bool = false) -> void:
	pattern.clear()
	for i in steps:
		pattern.append(dir)
	ping_pong_pattern = ping_pong
	_step = 0


## Trigger a single move step in the given direction.
## Safe to call externally — does nothing if already moving.
func move(direction: Vector3) -> void:
	if moving or target == null:
		return

	moving = true
	step_started.emit(direction)

	if move_sfx != null:
		move_sfx.play()

	var destination := Vector3(
		target.global_position.x + direction.x * cell_size,
		target.global_position.y,
		target.global_position.z + direction.z * cell_size
	)

	if rotate_to_face_direction and Vector3(direction.x, 0.0, direction.z) != Vector3.ZERO:
		var target_angle := atan2(direction.x, direction.z)
		var rot_tween := create_tween()
		rot_tween.tween_property(target, "rotation:y", target_angle, 1.0 / move_speed)

	var tween := create_tween()
	tween.tween_property(target, "global_position", destination, 1.0 / move_speed)
	await tween.finished

	moving = false
	step_finished.emit(direction)


## Advance one step through the configured pattern.
func pattern_move() -> void:
	if pattern.is_empty():
		return
	move(DIRECTION_MAP[pattern[_step]])
	_step += 1
	if _step >= pattern.size():
		if ping_pong_pattern:
			var flipped: Array[Direction] = []
			for d in pattern:
				flipped.append(DIRECTION_OPPOSITE[d])
			flipped.reverse()
			pattern = flipped
		_step = 0


func _on_player_moved(direction: Vector3) -> void:
	if chase_player:
		move(direction)
	else:
		pattern_move()


func _on_timer_timeout() -> void:
	pattern_move()
