extends Node

signal dice_moved(number: int)
signal cutscene_started(disable_input : bool)
signal cutscene_ended

# Signal for Hub 3D Viewer
signal side_editing_started(side: int)
signal side_updated_item(side: int, item: Card)
signal dice_viewer_rotation_speed_updated(new_speed: float)

var is_scene_transitioning : bool = false

func _ready():
	dice_moved.connect(on_dice_moved)
	SceneLoader.scene_loaded.connect(_on_scene_loaded)

func on_dice_moved(number: int):
	#print(number)
	pass

func _on_scene_loaded():
	is_scene_transitioning = false

func _on_scene_transition_start():
	is_scene_transitioning = true
