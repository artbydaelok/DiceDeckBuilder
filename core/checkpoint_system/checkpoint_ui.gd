extends Node
class_name CheckpointUI

const LEVEL_CHECKPOINT_DATA_CONTAINER = preload("uid://bffvo2bm3ta31")

@onready var tab_container: TabContainer = %TabContainer

var unlocked_checkpoints: Dictionary

func _ready() -> void:
	var save_system = get_tree().get_root().find_child("SaveSystem", true, false)
	GameEvents.menu_entered.emit()
	unlocked_checkpoints = save_system.player_data.unlocked_checkpoints
	
	_update_checkpoints()

func _update_checkpoints():
	# For each level
	for key in unlocked_checkpoints:
		# Create a tab for it.
		var tab : LevelCheckpointDataContainer = LEVEL_CHECKPOINT_DATA_CONTAINER.instantiate()

		tab_container.add_child(tab)
		
		# Set up the tab data
		tab.level_name = key
		tab.setup()
		
		for checkpoint in unlocked_checkpoints[key]:
			add_button(checkpoint, tab.level_button_container)


func add_button(checkpoint: String, container: VBoxContainer):
	var checkpoint_data: CheckpointData
	checkpoint_data = load(checkpoint)
	
	var button = Button.new()
	button.text = checkpoint_data.checkpoint_name
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.flat = true
	button.pressed.connect(on_checkpoint_button_pressed.bind(checkpoint_data))
	container.add_child(button)
	
func _on_button_pressed() -> void:
	GameEvents.menu_exited.emit()
	close()

func close():
	queue_free()
	
func on_checkpoint_button_pressed(checkpoint: CheckpointData):
	if checkpoint.level_name == GameEvents.current_level.level_name:
		get_tree().get_first_node_in_group("player").global_position = checkpoint.spawn_point + Vector3(0, 0, 2)
	else:
		GameEvents.current_checkpoint_data = checkpoint
		GameEvents.is_checkpoint_transfer = true
		SceneLoader.load_scene(checkpoint.level_path)
	GameEvents.menu_exited.emit()
	close()
		
