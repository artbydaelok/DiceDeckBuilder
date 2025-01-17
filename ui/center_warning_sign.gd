extends Control

@onready var warning_label: Label = %WarningLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var menu_return: bool = false

func resolve_warning():
	if menu_return:
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	else:
		queue_free()

func setup_and_play(warning_text: String):
	warning_label.text = warning_text
	animation_player.play("fade_in_n_out")
