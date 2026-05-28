# editor_line_edit.gd
# © Copyright CookieBadger 2026
@tool
extends LineEdit


# allows to submit with escape and on focus exitd.
func _ready() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return
	focus_exited.connect(on_focus_exited)
	gui_input.connect(input)


func input(p_event: InputEvent) -> void:
	if p_event is InputEventKey:
		if p_event.keycode == KEY_ESCAPE && p_event.pressed && has_focus():
			release_focus()


func on_focus_exited() -> void:
	text_submitted.emit(text)
