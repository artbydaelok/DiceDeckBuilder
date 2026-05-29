extends Enemy

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var grid_mover: GridMoverComponent = $GridMoverComponent

@export var spaces_to_move: int = 3
@export var reverse_direction: bool = false


func initialize() -> void:
	var dir := GridMoverComponent.Direction.FORWARD if reverse_direction else GridMoverComponent.Direction.BACK
	grid_mover.set_linear_pattern(dir, spaces_to_move, true)
	grid_mover.interval_time = 1.0 / move_speed
	grid_mover.step_started.connect(func(_dir): animation_player.play("jump"))
	grid_mover.start()


func apply_damage(damage: int) -> void:
	GameEvents.current_level.has_player_killed_frog = true
	super.apply_damage(damage)
