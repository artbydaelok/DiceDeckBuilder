extends Node
## Watches for ui_cancel and opens the pause menu.
## Attach this as a child of game_scene.tscn (or any level root).

const PAUSE_MENU = preload("res://ui/menus/pause_menu/pause_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if GameEvents.is_in_menu or GameEvents.is_in_cutscene:
		return
	if event.is_action_pressed("ui_cancel"):
		var menu := PAUSE_MENU.instantiate()
		get_tree().current_scene.add_child(menu)
