# editor_draw_panel.gd
# © Copyright CookieBadger 2026
extends Control


func _enter_tree() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_p_delta: float) -> void:
	if !Engine.is_editor_hint():
		return

	if get_parent() is Control:
		size = get_parent().size
