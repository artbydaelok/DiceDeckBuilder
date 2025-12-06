extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Console.add_command("load_level", load_level, ["Level Name"])

func load_level(level_id: String):
	match level_id: 
		"hub":
			SceneLoader.load_scene("res://levels/hub_level.tscn")
		"hell":
			SceneLoader.load_scene("res://levels/fire_demon_level.tscn")
		"forest":
			SceneLoader.load_scene("res://levels/forest_level.tscn")
		"street":
			SceneLoader.load_scene("res://levels/salt_and_pepper_level.tscn")
