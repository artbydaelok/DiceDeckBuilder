# link_button.gd
# © Copyright CookieBadger 2026
@tool
extends Button

const AssetPlacerPlugin = preload("res://addons/assetplacer/assetplacer_plugin.gd")

@export var url: String
@export var theme_icon: String = "ExternalLink"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return
	var root := EditorInterface.get_edited_scene_root()
	if not root or not root.is_ancestor_of(self):
		apply_icon()
		pressed.connect(open_link)


func apply_icon() -> void:
	var base_control := EditorInterface.get_base_control()
	icon = base_control.get_theme_icon(theme_icon, "EditorIcons")


func open_link() -> void:
	open_url(url)


static func open_url(p_url: String) -> void:
	OS.shell_open(p_url)
