extends "res://enemy/enemy_pawns/base_enemy_pawn.gd"

@onready var move_timer: Timer = $MoveTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var spaces_to_move : int = 3
var spaces_moved : int = 0

var move_direction : Vector3 = Vector3.BACK


# Triggers on ready / spawn
func initialize():
	move_timer.timeout.connect(on_timer_timeout)

# Triggers when player begins moving
func _on_player_moved(direction: Vector3): # OVERRIDABLE FUNCTION
	# Remove the comment on the next line if you want this enemy to move towards the camera every time the player moves.
	#grid_move_in_direction(Vector3.BACK)
	pass

# Triggers when player is done moving
func _on_player_rolled(): # OVERRIDABLE FUNCTION
	# TODO Should probably have the new active item be emitted here as well.
	pass

# Triggers on process / ever frame
func tick(delta): # OVERRIDABLE FUNCTION
	# Remove the comment (#) on the next line if you want this enemy to move towards the camera.
	#free_move_in_direction(Vector3.BACK) 
	pass

func on_timer_timeout():
	if spaces_moved < spaces_to_move:
		spaces_moved += 1
	else:
		spaces_moved = 0
		move_direction = -move_direction
	
	animation_player.play("jump")
	grid_move_in_direction(move_direction)

func apply_damage(damage):
	GameEvents.current_level.has_player_killed_frog = true
	queue_free()
