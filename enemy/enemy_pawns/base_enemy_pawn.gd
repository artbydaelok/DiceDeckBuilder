extends CharacterBody3D
class_name Enemy

@export var max_health: int = 1
var current_health: int

## Identifies this enemy's type for kill tracking / quests. If left blank,
## it is auto-derived from the scene filename (see _resolve_enemy_id()).
@export var enemy_id: String = ""

## Modifiers applied to this enemy at spawn — visual sheen + behavior + stat tweaks.
## Drop e.g. the Poison modifier here to make a Poisonous variant.
@export var modifiers: Array[EnemyModifier] = []

signal died

## How fast the enemy will move per second or per player move. By default 2.0 is one "tile".
@export var move_speed = 2.0

var player : Player
var initial_height: float

func _ready() -> void:
	_apply_modifiers()  # may change max_health before we read it
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	player.roll_finished.connect(_on_player_rolled)
	player.player_moved.connect(_on_player_moved)
	initial_height = global_position.y

	initialize()


## Apply each modifier's stat tweaks, visual overlay, and behavior node.
func _apply_modifiers() -> void:
	for mod in modifiers:
		if mod == null:
			continue
		max_health = int(round(max_health * mod.health_mult))
		move_speed *= mod.speed_mult
		if mod.overlay_material != null:
			for m in find_children("*", "MeshInstance3D", true, false):
				(m as MeshInstance3D).material_overlay = mod.overlay_material
		if mod.behavior_scene != null:
			add_child(mod.behavior_scene.instantiate())

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
