extends Control

@onready var warning_label: Label = %WarningLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var menu_return: bool = false

const MAIN_MENU = preload("res://addons/maaacks_game_template/base/scenes/menus/main_menu/main_menu.tscn")

func resolve_warning():
	if menu_return:
		get_tree().change_scene_to_packed(MAIN_MENU)
	else:
		queue_free()

func setup_and_play(warning_text: String):
	warning_label.text = warning_text
	animation_player.play("fade_in_n_out")
