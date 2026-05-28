# node_path_selector_glue.gd
# © Copyright CookieBadger 2026
@tool
extends Node

const NodePathSelectionButton = preload("res://addons/assetplacer/ui/components/node_path_selector/node_path_selection_button.gd")

@export var select_node_button: NodePathSelectionButton
@export var set_selected_button: Button

var text: String:
	get:
		var label := get_node_or_null("../Label")  # TOOD: why?
		return label.text if label else null
	set(value):
		var label := get_node_or_null("../Label")
		if label:
			label.text = value


func initialize() -> void:
	set_selected_button.disabled = true
	_setup_icons()
	EditorInterface.get_base_control().theme_changed.connect(_setup_icons)


func _setup_icons() -> void:
	var bc := EditorInterface.get_base_control()
	# apply special themes for hard edge buttons with no coloring
	var select_icon := bc.get_theme_icon("ListSelect", "EditorIcons")
	set_selected_button.text = ""
	set_selected_button.icon = select_icon


func set_selected_button_disabled(p_value: bool) -> void:
	set_selected_button.disabled = p_value


func set_node(p_node: Node, p_icon: Texture2D) -> void:
	select_node_button.set_node(p_node, p_icon)
