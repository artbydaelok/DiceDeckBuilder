extends Node
class_name CheckpointUI
#hub level vars
@onready var hub_level_checkpoints = %HubLevelButtonContainer
@onready var hub_level_texture = %HubLevelTextureRect

#forest level vars
@onready var forest_level_checkpoints = %ForestLevelButtonContainer
@onready var forest_level_texture = %ForestLevelTextureRect
#forest level vars
@onready var gausrothtest_level_checkpoints = %GausRothLevelButtonContainer
@onready var gausrothtest_level_texture = %GausRothLevelTextureRect

var unlocked_checkpoints: Dictionary

func _ready() -> void:
	var save_system = get_tree().get_root().find_child("SaveSystem", true, false)
	unlocked_checkpoints = save_system.player_data.unlocked_checkpoints
	
	_update_checkpoints()

func _update_checkpoints():
	for key in unlocked_checkpoints:
		match key:
			"Hub":
				for checkpoint in unlocked_checkpoints[key]:
					add_button(checkpoint, hub_level_checkpoints)
			"Forest":
				for checkpoint in unlocked_checkpoints[key]:
					add_button(checkpoint, forest_level_checkpoints)
			"GausRothTestLevel":
				for checkpoint in unlocked_checkpoints[key]:
					add_button(checkpoint, gausrothtest_level_checkpoints)

func add_button(checkpoint: String, container: VBoxContainer):
	var checkpoint_data: CheckpointData
	checkpoint_data = load(checkpoint)
	
	var button = Button.new()
	button.text = checkpoint_data.name
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.flat = true
	button.pressed.connect(on_checkpoint_button_pressed.bind(checkpoint))
	container.add_child(button)
	
func _on_button_pressed() -> void:
	print("queue_free")
	queue_free()
	
func on_checkpoint_button_pressed(checkpoint: CheckpointData):
	print("on_checkpoint_button_pressed: " + checkpoint.name)
