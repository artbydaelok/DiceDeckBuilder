# assetplacer_ui.gd
# © Copyright CookieBadger 2026
@tool
extends Control

const AssetPlacerPlugin = preload("res://addons/assetplacer/assetplacer_plugin.gd")
const AssetPaletteView = preload("res://addons/assetplacer/ui/asset_palette_view.gd")
const HelpDialog = preload("res://addons/assetplacer/ui/help_dialog.gd")
const PlacementConfigUI = preload("res://addons/assetplacer/ui/placement_config_ui/placement_config_ui.gd")
const SnappingConfigView = preload("res://addons/assetplacer/ui/snapping_config_ui/snapping_config_view.gd")
const DynamicPreviewView = preload("res://addons/assetplacer/ui/dynamic_preview_view.gd")
const ThemeBuilder = preload("res://addons/assetplacer/ui/theme_builder.gd")
const UIRegistry = preload("res://addons/assetplacer/ui_registry.gd")

#@export_tool_button("UpdateTheme", "Callable") var update_theme_action := tool_update_theme  # only works in 4.4+

@export var placement_config_ui: PlacementConfigUI
@export var help_dialog: HelpDialog
@export var help_button: Button
@export var about_dialog: AcceptDialog
@export var about_button: Button
@export var to_external_window_button: Button
@export var asset_palette_view: AssetPaletteView
@export var dynamic_preview_view: DynamicPreviewView
@export var snapping_config_view: SnappingConfigView


func initialize() -> void:
	snapping_config_view.initialize()
	placement_config_ui.initialize()
	asset_palette_view.initialize()
	reload_theme()
	EditorInterface.get_base_control().theme_changed.connect(reload_theme)


func register_nodes() -> void:
	UIRegistry.register(UIRegistry.MAIN_UI, self)  # test automation access
	placement_config_ui.register_nodes()
	snapping_config_view.register_nodes()
	dynamic_preview_view.register_nodes()
	asset_palette_view.register_nodes()


func reload_theme() -> void:
	theme = ThemeBuilder.create_theme_from_editor(false)
	to_external_window_button.text = ""
	to_external_window_button.icon = EditorInterface.get_base_control().get_theme_icon("MakeFloating", "EditorIcons")


static func clamp_window_to_screen(p_w: Window, p_base_control: Control) -> void:
	var screen_pos := DisplayServer.screen_get_position(p_base_control.get_window().current_screen)  # position of screen on a multi-monitor setup
	var min_pos := screen_pos + Vector2i.DOWN * 30
	var max_pos := screen_pos + DisplayServer.screen_get_size(p_base_control.get_window().current_screen) - p_w.size - Vector2i.DOWN * 30

	if min_pos < max_pos:
		p_w.position = p_w.position.clamp(min_pos, max_pos)  # clamp such that entire window is on screen
	else:
		p_w.position = min_pos


# func _notification(p_what: int) -> void:
# 	if p_what == NOTIFICATION_EDITOR_PRE_SAVE:
# 		if self == EditorInterface.get_edited_scene_root():  # prevent theme from being saved
# 			theme = null
# 			printerr("AssetPlacerPlugin: Asserplacer_ui.gd is not supposed to carry a theme. To prevent references to an external resource, theme has been removed.")


func tool_update_theme() -> void:
	var t: Theme = ThemeBuilder.create_theme_from_editor(true)
	var path := "res://assetplacer_editor_theme.tres"
	ResourceSaver.save(t, path)
	theme = ResourceLoader.load(path)
