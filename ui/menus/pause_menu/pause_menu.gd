extends Control
## Standalone pause menu — no Maaacks dependency.
## Pauses the scene tree when open, restores mouse mode and focus on close.

@export_file("*.tscn") var main_menu_scene_path: String = "res://ui/menus/main_menu/main_menu.tscn"

@onready var _menu_buttons: BoxContainer = %MenuButtons
@onready var _confirm_restart: ConfirmationDialog = %ConfirmRestart
@onready var _confirm_main_menu: ConfirmationDialog = %ConfirmMainMenu
@onready var _confirm_exit: ConfirmationDialog = %ConfirmExit

var _scene_tree: SceneTree
var _initial_pause_state: bool = false
var _initial_mouse_mode: Input.MouseMode
var _initial_focus_control: Control
var _initial_focus_mode: FocusMode = FOCUS_ALL


# ── Lifecycle ────────────────────────────────────────────────────────────────

func _enter_tree() -> void:
	_scene_tree = get_tree()
	_initial_pause_state = _scene_tree.paused
	_initial_mouse_mode = Input.get_mouse_mode()
	_initial_focus_control = get_viewport().gui_get_focus_owner()
	if _initial_focus_control:
		_initial_focus_mode = _initial_focus_control.focus_mode
	_scene_tree.paused = true


func _ready() -> void:
	_confirm_restart.confirmed.connect(_on_confirm_restart_confirmed)
	_confirm_main_menu.confirmed.connect(_on_confirm_main_menu_confirmed)
	_confirm_exit.confirmed.connect(_on_confirm_exit_confirmed)

	# Grab focus on the first button so the menu is navigable by keyboard/gamepad.
	# Without this, nothing is focused on open and the D-pad/stick does nothing.
	if _menu_buttons.get_child_count() > 0:
		(_menu_buttons.get_child(0) as Control).grab_focus.call_deferred()


# ── Input ────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# ── Public ───────────────────────────────────────────────────────────────────

func close() -> void:
	_scene_tree.paused = _initial_pause_state
	Input.set_mouse_mode(_initial_mouse_mode)
	if is_instance_valid(_initial_focus_control) and _initial_focus_control.is_inside_tree():
		_initial_focus_control.focus_mode = _initial_focus_mode
		_initial_focus_control.grab_focus()
	queue_free()


# ── Button handlers ──────────────────────────────────────────────────────────

func _on_resume_button_pressed() -> void:
	close()


func _on_restart_button_pressed() -> void:
	_confirm_restart.popup_centered()


func _on_main_menu_button_pressed() -> void:
	_confirm_main_menu.popup_centered()


func _on_exit_button_pressed() -> void:
	_confirm_exit.popup_centered()


func _on_confirm_restart_confirmed() -> void:
	_scene_tree.paused = false
	SceneLoader.reload_current_scene()


func _on_confirm_main_menu_confirmed() -> void:
	_scene_tree.paused = false
	SceneLoader.load_scene(main_menu_scene_path)


func _on_confirm_exit_confirmed() -> void:
	get_tree().quit()
