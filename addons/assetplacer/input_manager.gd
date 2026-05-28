# input_manager.gd
# © Copyright CookieBadger 2026
@tool
##### Singleton
const InputManager = preload("res://addons/assetplacer/input_manager.gd")
const Settings = preload("res://addons/assetplacer/settings.gd")
const Editor3DViewportUtils = preload("res://addons/assetplacer/utils/editor_3d_viewport_utils.gd")

const AP_CANCEL_KEY := KEY_ESCAPE
const MOVE_KEYS: Array[Key] = [KEY_W, KEY_A, KEY_S, KEY_D, KEY_Q, KEY_E]
const CONFIRM_KEYS: Array[Key] = [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]

signal vp_input

enum ActionType { NONE, PLACEMENT, ALT_PLACEMENT, CANCEL, MOVEMENT, CONFIRM, OTHER }

static var instance: InputManager:
	get:
		if !_instance:
			initialize()

		return _instance

static var _instance: InputManager

var viewport_actions: Dictionary[ActionType, Array] = {}
var viewport_actions_exact_modifier: Dictionary[ActionType, Array] = {}

var lmb_pressed: bool = false
var rmb_pressed: bool = false
var shift_pressed: bool = false

var ctrl_pressed: bool = false
var alt_pressed: bool = false

var screen_mouse_position: Vector2 = Vector2.ZERO
var viewport_mouse_position: Vector2 = Vector2.ZERO
var pressed_keys: Array[int] = []


static func initialize() -> void:
	_instance = InputManager.new()
	_instance._create_actions()
	EditorInterface.get_editor_settings().settings_changed.connect(_instance._create_actions)


func is_alt_placement_pressed() -> bool:
	return shift_pressed if Settings.get_setting(Settings.DEFAULT_CATEGORY, Settings.USE_SHIFT_SETTING) else alt_pressed


func _create_actions() -> void:
	var placement_event := InputEventMouseButton.new()
	placement_event.button_index = MOUSE_BUTTON_LEFT
	placement_event.pressed = true

	var alt_placement_event := placement_event.duplicate()
	if Settings.get_setting(Settings.DEFAULT_CATEGORY, Settings.USE_SHIFT_SETTING):
		alt_placement_event.shift_pressed = true
	else:
		alt_placement_event.alt_pressed = true

	var cancel_event := InputEventKey.new()
	cancel_event.keycode = AP_CANCEL_KEY
	cancel_event.pressed = true

	var movement_events := []
	for key in MOVE_KEYS:
		var move_event := InputEventKey.new()
		move_event.keycode = key
		move_event.pressed = true
		movement_events.append(move_event)

	var confirm_events := []
	for key in CONFIRM_KEYS:
		var confirm_event := InputEventKey.new()
		confirm_event.keycode = key
		confirm_event.pressed = true
		confirm_events.append(confirm_event)

	viewport_actions = {
		ActionType.PLACEMENT: [placement_event],
		ActionType.CANCEL: [cancel_event],
		ActionType.MOVEMENT: movement_events,
		ActionType.CONFIRM: confirm_events,
	}

	viewport_actions_exact_modifier = {
		ActionType.ALT_PLACEMENT: [alt_placement_event],
	}


func forward_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton:
		if p_event.button_index == MOUSE_BUTTON_RIGHT and not p_event.is_pressed():
			rmb_pressed = false
		elif p_event.button_index == MOUSE_BUTTON_LEFT and not p_event.is_pressed():
			lmb_pressed = false


func forward_3d_viewport_input(p_viewport: Viewport, p_event: InputEvent) -> ActionType:
	# update mouse position
	if p_event is InputEventMouse:
		if p_event is InputEventMouseButton:
			if p_event.button_index == MOUSE_BUTTON_LEFT:
				lmb_pressed = p_event.pressed
			elif p_event.button_index == MOUSE_BUTTON_RIGHT:
				rmb_pressed = p_event.pressed

	if not rmb_pressed:
		if p_event is InputEventMouse:
			viewport_mouse_position = p_event.position
		screen_mouse_position = viewport_mouse_position + p_viewport.get_screen_transform().origin

	# update modifier states
	if p_event is InputEventKey:
		if p_event.pressed:
			if not pressed_keys.has(p_event.keycode):
				pressed_keys.append(p_event.keycode)
		else:
			pressed_keys.erase(p_event.keycode)

		if p_event.keycode == KEY_SHIFT:
			shift_pressed = p_event.pressed
		elif p_event.keycode == KEY_CTRL:
			ctrl_pressed = p_event.pressed
		elif p_event.keycode == KEY_ALT:
			alt_pressed = p_event.pressed
	elif p_event is InputEventMouse:
		shift_pressed = p_event.shift_pressed
		ctrl_pressed = p_event.ctrl_pressed
		alt_pressed = p_event.alt_pressed

	var action: ActionType = ActionType.NONE
	# print("Event in input manager:", p_event)
	action = match_action(p_event, viewport_actions_exact_modifier, true)  # exact match has priority
	if action == ActionType.NONE:
		action = match_action(p_event, viewport_actions, false)
	# print("Action in input manager:", action)

	vp_input.emit()
	return action


func match_action(p_event: InputEvent, p_action_list: Dictionary[ActionType, Array], p_exact: bool) -> ActionType:
	# emit signals
	for action: ActionType in p_action_list.keys():
		for action_event: InputEvent in p_action_list[action]:
			if p_event.is_match(action_event, p_exact) and not p_event.is_echo() and p_event.is_pressed() == action_event.pressed:
				return action
	return ActionType.NONE
