extends Control



func _on_fire_demon_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/fire_demon_level.tscn")

func _on_salt_pepper_button_pressed() -> void:
	pass # Replace with function body.

func _on_jim_jam_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/jim_and_jam_level.tscn")

func _on_galaxy_boss_button_pressed() -> void:
	pass # Replace with function body.


func _on_close_button_pressed() -> void:
	visible = false
