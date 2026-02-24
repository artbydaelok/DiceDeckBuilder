extends Control
class_name LevelCheckpointDataContainer

@onready var level_button_container: VBoxContainer = %LevelButtonContainer

var level_name : String = "Level Name"

func _ready() -> void:
	setup()

func setup():
	name = level_name
