extends Control
class_name LevelCheckpointDataContainer

@onready var level_button_container: VBoxContainer = %LevelButtonContainer
@onready var checkpoint_picture: TextureRect = %CheckpointPicture

var level_name : String = "Level Name"

func _ready() -> void:
	setup()

func setup():
	name = level_name

func update_focus(checkpoint_data: CheckpointData):
	checkpoint_picture.texture = checkpoint_data.image
