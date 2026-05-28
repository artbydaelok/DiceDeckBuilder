# tag_label.gd
# © Copyright CookieBadger 2026
@tool
extends Label

const AssetPlacerPlugin = preload("res://addons/assetplacer/assetplacer_plugin.gd")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return
	var root := EditorInterface.get_edited_scene_root()
	if root == null || !root.is_ancestor_of(self):
		text = AssetPlacerPlugin.replace_tags(text)
