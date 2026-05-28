# shortcuts.gd
# © Copyright CookieBadger 2026
@tool
extends Object

const Settings = preload("res://addons/assetplacer/settings.gd")
const Shortcuts = preload("res://addons/assetplacer/shortcuts.gd")

const SHORTCUTS_CATEGORY: String = "Shortcuts"
const PLACEMENT_PLANE_POSITION = "Change_Placement_Plane_Position"
const TRANSFORM_ASSET: String = "Transform_Asset_Blueprint"
const SELECT_PREVIOUS_ASSET: String = "Select_Previous_Asset"
const DOUBLE_SNAP_STEP: String = "Double_Snap_Step"
const HALVE_SNAP_STEP: String = "Halve_Snap_Step"
const ROTATE_Y = "Rotate_Asset_90_Degrees_Around_Y"
const ROTATE_X = "Rotate_Asset_90_Degrees_Around_X"
const ROTATE_Z = "Rotate_Asset_90_Degrees_Around_Z"
const SHIFT_ROTATE_Y = "Rotate_Asset_Secondary_Step_Degrees_Around_Y"
const SHIFT_ROTATE_X = "Rotate_Asset_Secondary_Step_Degrees_Around_X"
const SHIFT_ROTATE_Z = "Rotate_Asset_Secondary_Step_Degrees_Around_Z"
const FLIP_X: String = "Flip_Asset_On_X_Axis"
const FLIP_Y: String = "Flip_Asset_On_Y_Axis"
const FLIP_Z: String = "Flip_Asset_On_Z_Axis"
const RESET_TRANSFORM: String = "Reset_Transform"
const SELECT_XZ_PLANE: String = "Select_X_Z_Plane"
const SELECT_YZ_PLANE: String = "Select_Y_Z_Plane"
const SELECT_XY_PLANE: String = "Select_X_Y_Plane"

static var instance: Shortcuts:
	get:
		if !_instance:
			initialize()

		return _instance

static var _instance: Shortcuts

var _shortcuts_3d_gui: Array[String] = []


static func initialize() -> void:
	_instance = Shortcuts.new()


func add_3d_gui_shortcut(p_name: String, p_event_keys: Array) -> void:
	_register_shortcut(p_name, p_event_keys)
	_shortcuts_3d_gui.append(p_name)


func add_simple_keys_3d_gui_shortcut(p_name: String, p_event_keys: Array) -> void:
	add_keys_3d_gui_shortcut(p_name, false, false, p_event_keys)


func add_keys_3d_gui_shortcut(p_name: String, p_shift: bool, p_ctrl: bool, p_event_keys: Array) -> void:
	var events: Array[InputEventKey] = []
	for key: Key in p_event_keys:
		var input_event := InputEventKey.new()
		input_event.keycode = key
		input_event.pressed = true
		input_event.echo = false
		input_event.shift_pressed = p_shift
		input_event.ctrl_pressed = p_ctrl
		events.append(input_event)

	add_3d_gui_shortcut(p_name, events)


static func get_shortcut_string(p_shortcut_name: String) -> String:
	var shortcut := Settings.get_setting(SHORTCUTS_CATEGORY, p_shortcut_name) as Shortcut
	var transform_str := ""
	if shortcut:
		for event: InputEvent in shortcut.events:
			if event is InputEventKey:
				var key_str := OS.get_keycode_string(event.keycode)
				var combine_str := ("CTRL+" if event.ctrl_pressed else "") + ("SHIFT+" if event.shift_pressed else "") + ("ALT+" if event.alt_pressed else "") + key_str
				transform_str += ("" if transform_str == "" else " / ") + combine_str
	return transform_str


func get_shortcut_string_dict() -> Dictionary[String, String]:
	var shortcuts_string_dict: Dictionary[String, String] = {}
	for shortcut in _shortcuts_3d_gui:
		shortcuts_string_dict[shortcut.replace("_", " ")] = get_shortcut_string(shortcut)

	return shortcuts_string_dict


func _register_shortcut(p_setting_name: String, p_event_keys: Array) -> void:
	# Register a new ProjectSetting, that contains the shortcut for the Placement Plane Position
	var shortcut := Shortcut.new()
	for key: InputEvent in p_event_keys:
		shortcut.events.append(key)
	Settings.register_setting(SHORTCUTS_CATEGORY, p_setting_name, shortcut, TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "Shortcut")


func is_shortcut(p_shortcut_name: String, p_input_event: InputEvent) -> bool:
	if p_input_event.is_echo() or not p_input_event.is_pressed():
		return false
	var setting: Variant = Settings.get_setting(SHORTCUTS_CATEGORY, p_shortcut_name)
	if setting is Shortcut:
		return setting.matches_event(p_input_event)

	return false


# for test automation
func create_shortcut_event(shortcut: String) -> InputEvent:  # for testing
	var setting: Variant = Settings.get_setting(SHORTCUTS_CATEGORY, shortcut)
	if setting is Shortcut and setting.events.size() > 0:
		return setting.events[0].duplicate()

	return null
