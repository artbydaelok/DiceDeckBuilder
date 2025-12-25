extends "res://enemy/enemy_pawns/base_enemy_pawn.gd"

@onready var move_timer: Timer = $MoveTimer
@onready var mesh: MeshInstance3D = $Visuals/Mesh

@export var pattern : Array[Vector3] = []
var step : int = 0

# Triggers on ready / spawn
func initialize():
	move_timer.timeout.connect(on_move_timer_timeout)

func on_move_timer_timeout():
	grid_move_in_direction(pattern[step])
	pattern[step] *= -1
	step += 1
	if step >= pattern.size():
		pattern.reverse()
		step = 0
	

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
