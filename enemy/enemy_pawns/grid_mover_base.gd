extends "res://enemy/enemy_pawns/base_enemy_pawn.gd"

@export_category("Grid-based pattern movement.")
## An array of normalized vectors indicating the direction the enemy is moving in per step. Can be empty if "player chase" behavior is used instead.
@export var pattern : Array[Vector3] = [] 
var step : int = 0

@export_subgroup("Using timer")
@onready var move_interval_timer: Timer
@export var interval_time : float = 0.75

@export_subgroup("Reacting to player movement.")
## If checked, the enemy will only move when the player moves. Otherwise, it will use a timer. 
@export var react_to_player_move : bool = false
@export var chase_player : bool = false

# Triggers on ready / spawn
func initialize():
	if not react_to_player_move:
		move_interval_timer.timeout.connect(on_move_timer_timeout)
		move_interval_timer.wait_time = interval_time
		move_interval_timer.start()
	
# Triggers when player begins moving
func _on_player_moved(direction: Vector3): # OVERRIDABLE FUNCTION
	if react_to_player_move:
		if chase_player:
			grid_move_in_direction(direction)
		else:
			pattern_move()

func on_move_timer_timeout():
	pattern_move()

# Triggers when player is done moving
func _on_player_rolled(): # OVERRIDABLE FUNCTION
	# TODO Should probably have the new active item be emitted here as well.
	pass

# Triggers on process / ever frame
func tick(delta): # OVERRIDABLE FUNCTION
	# Remove the comment (#) on the next line if you want this enemy to move towards the camera.
	#free_move_in_direction(Vector3.BACK) 
	pass

func pattern_move():
	grid_move_in_direction(pattern[step])
	pattern[step] *= -1
	step += 1
	if step >= pattern.size():
		pattern.reverse()
		step = 0
