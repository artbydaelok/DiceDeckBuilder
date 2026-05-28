# main_ui_controller.gd
# © Copyright CookieBadger 2026
@tool

const AssetPlacerUI = preload("res://addons/assetplacer/ui/assetplacer_ui.gd")
const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const AssetPlacerPlugin = preload("res://addons/assetplacer/assetplacer_plugin.gd")
const Shortcuts = preload("res://addons/assetplacer/shortcuts.gd")
const UIRegistry = preload("res://addons/assetplacer/ui_registry.gd")

var main_ui: AssetPlacerUI
var plugin: EditorPlugin  # access to plugin API


func _init(p_plugin: EditorPlugin) -> void:
	self.plugin = p_plugin
	# add bottom panel UI
	var assetplacer_ui_scene := load("res://addons/assetplacer/ui/assetplacer_ui.tscn")
	main_ui = assetplacer_ui_scene.instantiate()
	main_ui.initialize()
	_ui_to_bottom_panel()

	main_ui.help_button.pressed.connect(open_help_dialog)
	main_ui.about_button.pressed.connect(open_about_dialog)
	main_ui.to_external_window_button.pressed.connect(_on_ui_to_external)

	EditorInterface.get_base_control().get_window().mouse_entered.connect(_on_mouse_entered_window_from_external)


func _on_mouse_entered_window_from_external() -> void:
	# Switch focus to editor when moving from external window to editor.
	if (
		AssetPlacerState.instance.is_external_ui
		and AssetPlacerState.instance.palette_state.selected_asset != null
		and not AssetPlacerState.instance.mouse_over_external_ui
		and main_ui.get_window().has_focus()
	):
		EditorInterface.get_base_control().get_window().grab_focus()


func _on_ui_to_external() -> void:
	if AssetPlacerState.instance.is_external_ui:
		return

	AssetPlacerState.instance.is_external_ui = true
	plugin.remove_control_from_bottom_panel(main_ui)
	var w := Window.new()
	EditorInterface.get_base_control().get_window().add_child(w)
	w.title = AssetPlacerPlugin.ASSET_PLACER_TITLE
	w.exclusive = false
	w.transient = true
	w.wrap_controls = true
	w.close_requested.connect(_ui_to_bottom_panel)
	w.mouse_entered.connect(func() -> void: AssetPlacerState.instance.mouse_over_external_ui = true)
	w.mouse_exited.connect(func() -> void: AssetPlacerState.instance.mouse_over_external_ui = false)

	var bg := Panel.new()
	w.add_child(bg)
	w.add_child(main_ui)
	main_ui.visible = true
	w.size = Vector2i(main_ui.size)
	main_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.size = w.size
	#bg.theme_type_variation := "BackgroundPanelContainer" # nessesary?
	var bc := EditorInterface.get_base_control()
	w.position = bc.get_viewport().get_window().position + Vector2i(bc.get_viewport_rect().get_center()) - w.size / 2
	_on_attachment_changed(false)
	AssetPlacerUI.clamp_window_to_screen(w, bc)

	main_ui.register_nodes()


func _remove_external_ui_window() -> void:
	var w: Window = main_ui.get_parent()
	w.remove_child(main_ui)
	EditorInterface.get_base_control().get_window().remove_child(w)
	w.queue_free()


func _ui_to_bottom_panel() -> void:
	_on_attachment_changed(true)
	if AssetPlacerState.instance.is_external_ui:
		_remove_external_ui_window()
	AssetPlacerState.instance.mouse_over_external_ui = false
	AssetPlacerState.instance.is_external_ui = false
	plugin.add_control_to_bottom_panel(main_ui, AssetPlacerPlugin.ASSET_PLACER_TITLE)
	plugin.make_bottom_panel_item_visible(main_ui)

	main_ui.register_nodes()


func cleanup() -> void:
	_cleanup_ui()
	UIRegistry.clear()


func open_about_dialog() -> void:
	main_ui.about_dialog.position = main_ui.get_viewport().get_window().position + (main_ui.get_viewport_rect().get_center() as Vector2i) - main_ui.about_dialog.size / 2
	AssetPlacerUI.clamp_window_to_screen(main_ui.about_dialog, main_ui)
	if AssetPlacerPlugin.is_godot4_version_greater(1):
		var parent := main_ui.about_dialog.get_parent()
		if parent:
			parent.remove_child(main_ui.about_dialog)
		main_ui.about_dialog.owner = null
		main_ui.about_dialog.name = "AboutDialog"
		main_ui.about_dialog.popup_exclusive(main_ui)
	else:
		main_ui.about_dialog.popup()


func open_help_dialog() -> void:
	main_ui.help_dialog.position = main_ui.get_viewport().get_window().position + (main_ui.get_viewport_rect().get_center() as Vector2i) - main_ui.help_dialog.size / 2
	AssetPlacerUI.clamp_window_to_screen(main_ui.help_dialog, main_ui)
	main_ui.help_dialog.popup()
	main_ui.help_dialog.init_shortcut_table(Shortcuts.instance.get_shortcut_string_dict())


func _on_attachment_changed(p_attached: bool) -> void:
	main_ui.to_external_window_button.visible = p_attached
	if p_attached:
		var abd := main_ui.about_dialog
		var about_parent := abd.get_parent()
		if about_parent:
			about_parent.remove_child(main_ui.about_dialog)


func _cleanup_ui() -> void:
	if main_ui != null:
		if AssetPlacerState.instance.is_external_ui:
			_remove_external_ui_window()
		else:
			plugin.remove_control_from_bottom_panel(main_ui)
		main_ui.queue_free()
		main_ui = null
