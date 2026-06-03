extends CharacterBody3D
class_name Enemy

@export var max_health: int = 1
var current_health: int

## Identifies this enemy's type for kill tracking / quests. If left blank,
## it is auto-derived from the scene filename (see _resolve_enemy_id()).
@export var enemy_id: String = ""

signal died

## How fast the enemy will move per second or per player move. By default 2.0 is one "tile".
@export var move_speed = 2.0

var player : Player
var initial_height: float

func _ready() -> void:
	current_health = max_health
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
	pass

# Triggers when player is done moving
func _on_player_rolled(): # OVERRIDABLE FUNCTION
	pass

func tick(delta): # OVERRIDABLE FUNCTION
	pass

func on_died() -> void:
	queue_free()
#endregion # OVERRIDABLE FUNCTIONS

func apply_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		GameEvents.enemy_killed.emit(_resolve_enemy_id())
		died.emit()
		on_died()

## Returns the type id used for kill tracking. Prefers the exported enemy_id,
## then the scene filename (e.g. "frog_enemy"), then the node name.
func _resolve_enemy_id() -> String:
	if enemy_id != "":
		return enemy_id
	if scene_file_path != "":
		return scene_file_path.get_file().get_basename()
	return name.to_lower()

func _physics_process(delta: float) -> void:
	tick(delta)
	move_and_slide()

# Movement should be restricted to a grid.

# Some attacks hit only grounded enemies, while others may only hit flying enemies. Some attacks can do both.
