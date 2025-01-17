extends Node

@onready var level_select_menu: Control = $UI/LevelSelectMenu


func _on_level_select_button_pressed() -> void:
	level_select_menu.visible = true

func _on_edit_deck_button_pressed() -> void:
	pass # Replace with function body.

func _on_options_button_pressed() -> void:
	pass # Replace with function body.

func _on_exit_button_pressed() -> void:
	get_tree().quit()
