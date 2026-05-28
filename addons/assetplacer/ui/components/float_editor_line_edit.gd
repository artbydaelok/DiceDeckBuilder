# float_editor_line_edit.gd
# © Copyright CookieBadger 2026
@tool
extends LineEdit

signal float_submitted(value: float)
signal float_edited(value: float)

var allow_expressions := true

## setting this will update the text unless we are currently editing, in which case it will
## update only after exiting edit mode, if no newer edit happens.s
var value: float = 0.0:
	get:
		if is_editing:
			return text.to_float()
		return value
	set(val):
		# in the case that we just typed that value, don't change the text, but cache it,
		# just in case it was different and more up to date.
		if _is_editing:
			_value_cache = val
			_cache_valid = true
			return

		text = str(val)
		value = val

var _is_editing: bool = false
var _value_cache: float = 0.0
var _cache_valid := false


func exit_edit() -> void:
	_is_editing = false
	release_focus()


func _ready() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if not Engine.is_editor_hint() or (root and root.is_ancestor_of(self)):
		return
	text = "0.0"
	text_submitted.connect(_on_text_submitted)
	text_changed.connect(_on_text_edited)
	focus_exited.connect(
		func() -> void:
			on_focus_exited()
			_is_editing = false
			if _cache_valid:
				_cache_valid = false
				value = _value_cache
	)
	gui_input.connect(input)


func input(p_event: InputEvent) -> void:
	if p_event is InputEventKey:
		if p_event.keycode == KEY_ESCAPE && p_event.pressed && has_focus():
			if _is_editing and _cache_valid:
				_cache_valid = false
				value = _value_cache

			release_focus()


func on_focus_exited() -> void:
	if _is_editing:  # we haven't submitted yet
		_is_editing = false
		if _cache_valid:  # cache is newer than what we last typed
			_cache_valid = false
			value = _value_cache
		else:  # typed value is newer
			value = text.to_float()
			float_submitted.emit(text.to_float())


func _on_text_edited(p_new_text: String) -> void:
	_is_editing = true

	if allow_expressions:
		var result := _evaluate_expression(p_new_text)
		if result[0]:
			float_edited.emit(result[1])
			_cache_valid = false
			return

	if p_new_text.is_valid_float():
		float_edited.emit(p_new_text.to_float())
		_cache_valid = false


func _on_text_submitted(p_new_text: String) -> void:
	# ENTER was pressed, while the field had focus -> definitely apply the value
	_cache_valid = false
	_is_editing = false
	release_focus()

	if allow_expressions:
		var result := _evaluate_expression(p_new_text)
		if result[0]:
			value = result[1]
			float_submitted.emit(value)
			_cache_valid = false
			return

	value = p_new_text.to_float()
	float_submitted.emit(value)


func _evaluate_expression(p_text: String) -> Array:
	var expr := Expression.new()
	var err := expr.parse(p_text)
	if err == OK:
		var result: Variant = expr.execute([], null, false)
		if not expr.has_execute_failed():
			return [true, result]
	return [false, 0.0]
