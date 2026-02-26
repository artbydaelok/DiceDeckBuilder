extends Node

signal dice_moved(number: int)
signal cutscene_started(disable_input : bool)
signal cutscene_ended


signal menu_entered
signal menu_exited
var is_in_menu : bool = false
var menus_open : int = 0

# Signal for Hub 3D Viewer
signal side_editing_started(side: int)
signal side_updated_item(side: int, item: Card)
signal dice_viewer_rotation_speed_updated(new_speed: float)

var is_scene_transitioning : bool = false

var current_level : Level

var is_checkpoint_transfer : bool = false
var current_checkpoint_data : CheckpointData

func _ready():
	dice_moved.connect(on_dice_moved)
	SceneLoader.scene_loaded.connect(_on_scene_loaded)
	menu_entered.connect(_on_menu_entered)
	menu_exited.connect(_on_menu_exited)
	
func _on_menu_entered():
	menus_open += 1
	is_in_menu = true

func _on_menu_exited():
	menus_open -= 1
	is_in_menu = menus_open > 0
	
func on_dice_moved(number: int):
	#print(number)
	pass

func _on_scene_loaded():
	menus_open = 0
	is_scene_transitioning = false

func _on_scene_transition_start():
	is_scene_transitioning = true

func disable_player_input():
	var player = get_tree().get_first_node_in_group("player")
	player.input_disabled = true

func enable_player_input():
	var player = get_tree().get_first_node_in_group("player")
	player.input_disabled = false
