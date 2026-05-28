# about_dialog.gd
# © Copyright CookieBadger 2026
@tool
extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return
	var file := FileAccess.open("res://addons/assetplacer/EULA.txt", FileAccess.READ)

	get_node("%License").text = file.get_as_text()

	file.close()
