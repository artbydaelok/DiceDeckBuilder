# right_click_popup_submenu.gd
# © Copyright CookieBadger 2026
@tool
extends PopupMenu

signal submenu_selected(parent_id: int, id: int)

var parent_id: int


func _init(p_parent_id: int = 0) -> void:
	self.parent_id = p_parent_id


func _ready() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return
	id_pressed.connect(func(id: int) -> void: submenu_selected.emit(parent_id, id))
