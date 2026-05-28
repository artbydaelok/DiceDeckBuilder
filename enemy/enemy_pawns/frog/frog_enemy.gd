extends Enemy

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var grid_mover: GridMoverComponent = $GridMoverComponent

@export var spaces_to_move: int = 3
@export var reverse_direction: bool = false


func initialize() -> void:
	# Build the ping-pong pattern from spaces_to_move.
	# GridMoverComponent will reverse it automatically at the end of each pass.
	var dir := Vector3.FORWARD if reverse_direction else Vector3.BACK
	for i in spaces_to_move:
		grid_mover.pattern.append(dir)
	grid_mover.ping_pong_pattern = true
	grid_mover.interval_time = 1.0 / move_speed
	grid_mover.step_started.connect(func(_dir): animation_player.play("jump"))
	grid_mover.start()


func apply_damage(damage: int) -> void:
	GameEvents.current_level.has_player_killed_frog = true
	super.apply_damage(damage)
