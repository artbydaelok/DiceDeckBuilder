extends Control
## Standalone main menu — no Maaacks / AppConfig dependency.

@export_file("*.tscn") var game_scene_path: String = "res://cutscenes/opening_cutscene.tscn"

@onready var crt_shader_layer: CanvasLayer = $CRTShaderLayer
@onready var menu_layer: CanvasLayer = $MenuLayer

@onready var new_game_button: Button = %NewGameButton
@onready var options_button: Button = %OptionsButton
@onready var credits_button: Button = %CreditsButton
@onready var exit_button: Button = %ExitButton

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	crt_shader_layer.visible = true

	if OS.has_feature("web"):
		exit_button.hide()

	if game_scene_path.is_empty():
		new_game_button.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_accept") and get_viewport().gui_get_focus_owner() == null:
		new_game_button.grab_focus()


func _on_new_game_button_pressed() -> void:
	SceneLoader.load_scene(game_scene_path)


func _on_options_button_pressed() -> void:
	pass  # TODO: wire up a standalone options menu when ready


func _on_credits_button_pressed() -> void:
	pass  # TODO: wire up credits when ready


func _on_exit_button_pressed() -> void:
	get_tree().quit()
