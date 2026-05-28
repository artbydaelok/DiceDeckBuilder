# tooltip_panel.gd
# © Copyright CookieBadger 2026
@tool
extends "res://addons/assetplacer/utils/editor_draw_panel.gd"

const TooltipPanel = preload("res://addons/assetplacer/tooltip_panel.gd")
const Settings = preload("res://addons/assetplacer/settings.gd")

const TOOLTIPS_CATEGORY: String = "Tooltips"

const DISABLE_TOOLTIPS: String = "Disable_All_Tooltips"
const DISABLE_ERROR_TOOLTIPS: String = "Disable_Error_Tooltips"
const DISABLE_HINT_TOOLTIPS: String = "Disable_Hint_Tooltips"
const DISABLE_VALUE_TOOLTIPS: String = "Disable_Value_Tooltips"

const COLOR_DEFAULT = Color.WHITE
const COLOR_ERROR = Color.SALMON
const COLOR_HINT = Color(1.0, 1.0, 1.0, 0.5)
const COLOR_HINT_IMPORTANT = Color(1.0, 0.72, 0.0)
const FONT_SIZE = 12
const VALUE_FONT_SIZE = 14

enum TYPE { DEFAULT, VALUE, ERROR, HINT, HINT_IMPORTANT }

static var instance: TooltipPanel


class Tooltip:
	var text: String
	var font: Font
	var type: TYPE
	var priority: int = 0
	var children: Dictionary[String, Tooltip] = {}
	var exclusive: bool = false
	var lock_to_first_pos: bool = false
	var first_pos: Vector2 = -Vector2.ONE  # minus one = not yet set


var _tooltips: Dictionary[String, Tooltip] = {}
var _tooltip_rect: Rect2i
var _mouse_position: Vector2

## Set the text of a tooltip with a unique path.
## A tooltip with the same path of an existing tooltip will override the existing tooltip
## The path can be used to create a hierarchy of tooltips, where child tooltips will all be removed when the parent is updated or cleared.
## Children can also be kept when updating a parent tooltip by specifying them within brackets.
## E.g.:
## set_tt("parent/child1", "Hello World") -> creates tooltip "parent/child1", shows "Hello World"
## set_tt("parent/child2", "Nice weather") -> creates tooltip "parent/child2". Shows "Hello World" and "Nice weather"
## set_tt("parent[child2]", "Good job!") -> updates tooltip "parent", keeping child2. Shows "Good job!" and "Nice weather".
## set_tt("parent", "New text") -> updates tooltip "parent", removing children. Shows "New text".
## exclusive: If true, this tooltip will hide all sibling tooltips when shown. Useful for overriding other tooltips


static func set_tt(path_info: String, p_text: String, p_type: TYPE = TYPE.DEFAULT, p_priority: int = 0, p_exclusive: bool = false, p_lock_to_first_pos: bool = false) -> void:
	var id_path := path_info
	var kept_children: PackedStringArray = []
	if path_info.ends_with("]"):
		var split := path_info.substr(0, path_info.length() - 1).split("[")
		id_path = split[0]
		kept_children = split[1].split(",")
	instance._set_tooltip(instance._tooltips, p_text, id_path, kept_children, p_type, p_priority, p_exclusive, p_lock_to_first_pos)


static func clear_tt(id_path: String) -> void:
	instance._clear_tooltip(instance._tooltips, id_path)


static func clear_tooltips() -> void:
	instance._tooltips.clear()


static func _get_color(p_type: TYPE) -> Color:
	match p_type:
		TYPE.DEFAULT:
			return COLOR_DEFAULT
		TYPE.VALUE:
			return COLOR_DEFAULT
		TYPE.ERROR:
			return COLOR_ERROR
		TYPE.HINT:
			return COLOR_HINT
		TYPE.HINT_IMPORTANT:
			return COLOR_HINT_IMPORTANT
	return COLOR_DEFAULT


func update_position(p_tooltip_rect: Rect2i, _p_pos: Vector2) -> void:
	_tooltip_rect = p_tooltip_rect
	_mouse_position = _p_pos


func _init() -> void:
	instance = self
	Settings.register_setting(TOOLTIPS_CATEGORY, DISABLE_TOOLTIPS, false, TYPE_BOOL)
	Settings.register_setting(TOOLTIPS_CATEGORY, DISABLE_ERROR_TOOLTIPS, false, TYPE_BOOL)
	Settings.register_setting(TOOLTIPS_CATEGORY, DISABLE_HINT_TOOLTIPS, false, TYPE_BOOL)
	Settings.register_setting(TOOLTIPS_CATEGORY, DISABLE_VALUE_TOOLTIPS, false, TYPE_BOOL)


func _draw() -> void:
	if Settings.get_setting(TOOLTIPS_CATEGORY, DISABLE_TOOLTIPS):
		return

	if _tooltips.size() == 0:
		return

	const CURSOR_Y_OFF := 48
	var h := CURSOR_Y_OFF
	var prev_font_size := 0

	var line_data := _get_lines()
	var lines: Array[String] = line_data[0]
	var flattened_tooltips: Array[Tooltip] = line_data[1]
	var size := Vector2.ZERO
	if lines.size() > 0:
		size.x = lines.map(func(l: String) -> int: return l.length()).max()
		size.y = flattened_tooltips.reduce(func(accum: int, line: Tooltip) -> int: return accum + _get_font_size(line), 0)
	var pos_x: float = min(_tooltip_rect.end.x - size.x * 4, max(_tooltip_rect.position.x + size.x * 4, _mouse_position.x))
	var pos_y: float = min(_tooltip_rect.end.y - (size.y + CURSOR_Y_OFF + 10), max(_tooltip_rect.position.y, _mouse_position.y))
	var position := Vector2(pos_x, pos_y)

	for i in range(lines.size()):
		h += prev_font_size * 4.0 / 3.0
		var t := flattened_tooltips[i]
		var color := _get_color(t.type)
		color.a = min(color.a, 0.8)
		var s := _get_font_size(t)
		var pos := position + Vector2(-128, h)
		if t.lock_to_first_pos:
			if t.first_pos == -Vector2.ONE:
				t.first_pos = pos
			pos = t.first_pos
		draw_string(t.font, pos, lines[i], HORIZONTAL_ALIGNMENT_CENTER, 256, s, color)
		prev_font_size = s


func _get_font_size(t: Tooltip) -> int:
	var font_size := FONT_SIZE
	match t.type:
		TYPE.DEFAULT:
			font_size = FONT_SIZE
		TYPE.VALUE:
			font_size = VALUE_FONT_SIZE
		TYPE.ERROR:
			font_size = FONT_SIZE
		TYPE.HINT:
			font_size = FONT_SIZE
		TYPE.HINT_IMPORTANT:
			font_size = FONT_SIZE
	return font_size


func _get_lines() -> Array:
	var flat_tooltips: Array[Tooltip] = []
	var tooltips := _flatten_and_filter_tooltips(_tooltips.values())
	var lines: Array[String] = []
	for t in tooltips:
		for line in t.text.split("\n"):
			lines.append(line)
			flat_tooltips.append(t)
	return [lines, flat_tooltips]


func _flatten_and_filter_tooltips(tooltips: Array[Tooltip]) -> Array[Tooltip]:
	var result: Array[Tooltip] = []
	var sorted_tooltips := tooltips
	sorted_tooltips.sort_custom(func(a: Tooltip, b: Tooltip) -> bool: return a.priority - b.priority > 0)
	for t in sorted_tooltips:
		if t.exclusive:
			result.clear()

		if not _is_disabled(t.type):
			if t.text:
				result.append(t)
			if t.children.size() > 0:
				var children := _flatten_and_filter_tooltips(t.children.values())
				result.append_array(children)

		if t.exclusive:
			break

	return result


func _is_disabled(p_type: TYPE) -> bool:
	match p_type:
		TYPE.ERROR:
			return Settings.get_setting(TOOLTIPS_CATEGORY, DISABLE_ERROR_TOOLTIPS)
		TYPE.HINT:
			return Settings.get_setting(TOOLTIPS_CATEGORY, DISABLE_HINT_TOOLTIPS)
		TYPE.HINT_IMPORTANT:
			return Settings.get_setting(TOOLTIPS_CATEGORY, DISABLE_HINT_TOOLTIPS)
		TYPE.VALUE:
			return Settings.get_setting(TOOLTIPS_CATEGORY, DISABLE_VALUE_TOOLTIPS)
	return false


func _set_tooltip(
	r_dict: Dictionary[String, Tooltip],
	p_text: String,
	id_path: String,
	kept_children: PackedStringArray = [],
	p_type: TYPE = TYPE.DEFAULT,
	p_priority: int = 0,
	p_exclusive: bool = false,
	p_lock_to_first_pos: bool = false
) -> void:
	var p := id_path.find("/")
	if p >= 0:
		var parent := id_path.substr(0, p)
		var child_id := id_path.substr(p + 1)
		if not r_dict.has(parent):  # empty parent
			var tooltip := Tooltip.new()
			r_dict[parent] = tooltip
			tooltip.text = ""
		_set_tooltip(r_dict[parent].children, p_text, child_id, kept_children, p_type, p_priority, p_exclusive, p_lock_to_first_pos)
	else:
		var tooltip := Tooltip.new()
		if r_dict.has(id_path):
			tooltip = r_dict[id_path]
			for c: String in tooltip.children.keys():
				if not kept_children.has(c):
					tooltip.children.erase(c)
		r_dict[id_path] = tooltip
		tooltip.text = p_text
		tooltip.type = p_type
		tooltip.font = EditorInterface.get_base_control().get_theme_font("main", "EditorFonts")
		tooltip.priority = p_priority
		tooltip.exclusive = p_exclusive
		tooltip.lock_to_first_pos = p_lock_to_first_pos


func _clear_tooltip(r_dict: Dictionary[String, Tooltip], id_path: String) -> void:
	var p := id_path.find("/")
	if p >= 0:
		var parent := id_path.substr(0, p)
		if r_dict.has(parent):
			var child_id := id_path.substr(p + 1)
			_clear_tooltip(r_dict[parent].children, child_id)
			if r_dict[parent].children.size() == 0 and not r_dict[parent].text:
				r_dict.erase(parent)
	elif id_path in r_dict:
		r_dict.erase(id_path)


static func dump_tooltip_tree() -> void:
	print("Dumping tooltip tree:")
	instance._dump_tooltip_subtree(instance._tooltips, "")


func _dump_tooltip_subtree(subtree: Dictionary[String, Tooltip], indent: String) -> void:
	for key: String in subtree.keys():
		var tooltip := subtree[key]
		print("%s- %s: %s" % [indent, key, tooltip.text])
		_dump_tooltip_subtree(tooltip.children, indent + "  ")
