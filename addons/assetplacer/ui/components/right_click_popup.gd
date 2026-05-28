# right_click_popup.gd
# © Copyright CookieBadger 2026
@tool
extends PopupMenu

const RightClickPopupSubmenu = preload("res://addons/assetplacer/ui/components/right_click_popup_submenu.gd")

var item_path: String
var actions: Dictionary[int, Callable]
var conditions: Dictionary[int, Callable]
var action_signals: Dictionary[int, StringName]
var enum_actions: Dictionary[int, Callable]


func _ready() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return
	id_pressed.connect(_on_entry_pressed)


func _on_entry_pressed(id: int) -> void:
	if action_signals.has(id):
		actions[id].call(action_signals[id], item_path)
	elif actions.has(id):
		actions[id].call(item_path)


func update_conditions() -> void:
	for id: int in conditions.keys():
		set_item_disabled(id, !conditions[id].call(item_path))


func add_entry(p_label: String, p_icon: Texture2D, p_on_pressed: Callable, p_accelerator: Key = KEY_NONE) -> void:
	var before_item_count := item_count
	add_icon_item(p_icon, p_label, item_count, p_accelerator)
	actions[before_item_count] = p_on_pressed


func add_entry_with_accel(p_label: String, p_icon: Texture2D, p_on_pressed: Callable, p_accelerator: Key = KEY_NONE) -> void:
	var before_item_count := item_count
	add_icon_item(p_icon, p_label, item_count, p_accelerator)
	actions[before_item_count] = p_on_pressed


func add_signal_entry(p_label: String, p_icon: Texture2D, p_on_pressed: Callable, p_signal_name: StringName) -> void:
	var before_item_count := item_count
	add_entry(p_label, p_icon, p_on_pressed)
	action_signals[before_item_count] = p_signal_name


func add_condition_entry(p_label: String, p_icon: Texture2D, p_on_pressed: Callable, p_condition: Callable) -> void:
	var before_item_count := item_count
	add_entry(p_label, p_icon, p_on_pressed)
	conditions[before_item_count] = p_condition


func add_enum_entry(p_label: String, p_on_pressed: Callable, p_sub_entries: PackedStringArray) -> void:
	var before_item_count := item_count
	var submenu_popup: RightClickPopupSubmenu = RightClickPopupSubmenu.new(item_count)
	submenu_popup.name = p_label
	add_submenu_node_item(p_label, submenu_popup, item_count)  # adds submenu as child
	enum_actions[before_item_count] = p_on_pressed

	var sub := 0
	for entry in p_sub_entries:
		submenu_popup.add_radio_check_item(entry, sub)
		sub += 1
	actions[before_item_count] = p_on_pressed
	submenu_popup.submenu_selected.connect(func(id: int, sub_id: int) -> void: enum_actions[id].call(item_path, sub_id))


func set_enum_entry_checked(p_label: String, p_idx: int) -> void:
	var submenu := get_node(p_label)
	for i in range(submenu.item_count):
		submenu.set_item_checked(i, i == p_idx)
