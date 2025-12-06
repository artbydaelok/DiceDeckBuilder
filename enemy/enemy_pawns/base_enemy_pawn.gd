extends CharacterBody3D

## How fast the enemy will move per second or per player move. By default 2.0 is one "tile".
@export var move_speed = 2.0 

var player : Player
var initial_height: float


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	player.roll_finished.connect(_on_player_rolled)
	player.player_moved.connect(_on_player_moved)
	initial_height = global_position.y

	initialize()
#region # OVERRIDABLE FUNCTIONS
func initialize(): # OVERRIDABLE FUNCTION
	pass
	
# Triggers when player begins moving
func _on_player_moved(direction: Vector3): # OVERRIDABLE FUNCTION
	#grid_move_in_direction(Vector3.BACK)
	pass

# Triggers when player is done moving
func _on_player_rolled(): # OVERRIDABLE FUNCTION
	# TODO Should probably have the new active item be emitted here as well.
	pass

func tick(delta): # OVERRIDABLE FUNCTION
	pass
#endregion # OVERRIDABLE FUNCTIONS

func grid_move_in_direction(direction: Vector3):
	var tween := create_tween()
	var target_position : Vector3 = Vector3(global_position.x + direction.x * move_speed, initial_height, global_position.z + direction.z * 2)
	tween.tween_property(self, "global_position", target_position, 0.1)
	await tween.finished

func free_move_in_direction(direction := Vector3.BACK):
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)


func _physics_process(delta: float) -> void:
	tick(delta)
	move_and_slide()

# Movement should be restricted to a grid.

# Some attacks hit only grounded enemies, while others may only hit flying enemies. Some attacks can do both.
