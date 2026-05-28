# dynamic_preview_view.gd
# © Copyright CookieBadger 2026
@tool
extends Control

const UIRegistry = preload("res://addons/assetplacer/ui_registry.gd")
const Settings = preload("res://addons/assetplacer/settings.gd")
const AssetPlacerButton = preload("res://addons/assetplacer/ui/assetplacer_button.gd")

const CONFIRM_PREVIEW_KEY := KEY_SPACE
const PREVIEW_COLOR := "Dynamic_Preview_Background_Color"

@warning_ignore("unused_signal")
signal on_coordinates_edited(spherical_cam_coordinates: Vector3)
signal input_event(event: InputEvent)
signal close(asset_path: String, update_preview: bool)

@export var texture_rect: TextureRect
@export var asset_name_label: Label
@export var background_panel: Panel
@export var close_button: Button
@export var update_button: Button
@export var preview_panel: Control

var _asset_button: AssetPlacerButton


func initialize(p_preview_texture: Texture2D) -> void:
	update_button.tooltip_text = "Update the thumbnail shown in the library (%s)" % [str(CONFIRM_PREVIEW_KEY)]

	resized.connect(reposition)
	close_button.pressed.connect(close_preview.bind(false))
	update_button.pressed.connect(close_preview.bind(true))
	Settings.register_setting(Settings.DEFAULT_CATEGORY, PREVIEW_COLOR, Color("777777"), TYPE_COLOR)
	texture_rect.texture = p_preview_texture

	_setup_icons()
	EditorInterface.get_base_control().theme_changed.connect(_setup_icons)


func register_nodes() -> void:
	UIRegistry.register(UIRegistry.DYNPREV_VIEW, self)
	UIRegistry.register(UIRegistry.DYNPREV_CLOSE_BUTTON, close_button)
	UIRegistry.register(UIRegistry.DYNPREV_UPDATE_BUTTON, update_button)


func process(p_spherical_cam_coordinates: Vector3) -> void:
	if Engine.is_editor_hint():
		var theta := p_spherical_cam_coordinates
		var mat := background_panel.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("theta", theta)
			var color: Color = Settings.get_setting(Settings.DEFAULT_CATEGORY, PREVIEW_COLOR)
			mat.set_shader_parameter("color", color)


func _setup_icons() -> void:
	close_button.icon = EditorInterface.get_base_control().get_theme_icon("Close", "EditorIcons")
	close_button.text = ""


func _input(event: InputEvent) -> void:
	if !Engine.is_editor_hint():
		return

	if !visible:
		return

	if event is InputEventKey && texture_rect.has_focus():
		if (event.keycode == AssetPlacerButton.TOGGLE_DYNAMIC_PREVIEW_KEY || event.keycode == KEY_ESCAPE || event.keycode == CONFIRM_PREVIEW_KEY) && event.is_pressed() && !event.is_echo():
			close_preview(event.keycode == CONFIRM_PREVIEW_KEY)
			get_tree().root.set_input_as_handled()

	input_event.emit(event)


func show_preview(p_show_over: Control, p_name: String, p_path: String) -> void:
	_asset_button = p_show_over
	asset_name_label.text = p_name
	asset_name_label.tooltip_text = p_path
	reposition()
	_grab_focus()


# override
func _grab_focus() -> void:
	texture_rect.grab_focus()


# override
func _has_focus() -> bool:
	return texture_rect.has_focus()


func reposition() -> void:
	if _asset_button == null || !visible:
		return
	var button_pos_relative_to_parent := _asset_button.get_global_rect().get_center() - global_position
	var pos_on_button := button_pos_relative_to_parent - Vector2(preview_panel.size.x / 2.0, preview_panel.size.y / 2.0)
	var pos: Vector2 = get_parent().size - preview_panel.size
	var max_pos := Vector2(max(pos.x, 0.0), max(pos.y, 0.0))
	preview_panel.position = pos_on_button.clamp(Vector2.ZERO, max_pos)


func close_preview(p_update_preview: bool) -> void:
	close.emit(_asset_button.asset_path, p_update_preview)
