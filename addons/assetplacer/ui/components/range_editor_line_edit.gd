# range_editor_line_edit.gd
# © Copyright CookieBadger 2026
@tool
extends LineEdit

const InputManager = preload("res://addons/assetplacer/input_manager.gd")

## If you wonder why I am not using EditorSpinSlider:
## - Slider does not support evaluation at edit time (live evaluating while typing)
## - Slider is hard to style, I just can't find a way to change the font color, e.g.

signal float_submitted(value: float)
signal float_edited(value: float)

var allow_expressions := true
var max_value := 1.0
var min_value := 0.0
var allow_greater := true
var allow_lesser := true
var step := 0.001

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
		var clamped_val := _clamp(_get_closest_step(val))
		value = clamped_val
		text = str(clamped_val)

var _value_before_edit: float
var _is_editing: bool = false
var _value_cache: float = 0.0
var _cache_valid := false

var _dragging := false
var _drag_threshold_passed := false
var _drag_start_mouse_pos: Vector2
var _drag_mouse_total: Vector2
var _drag_start_value: float


func _init() -> void:
	step = EditorInterface.get_editor_settings().get_setting("interface/inspector/default_float_step")


func exit_edit() -> void:
	_is_editing = false
	release_focus()


func is_editing_or_dragging() -> bool:
	return _is_editing or _dragging


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
	focus_entered.connect(
		func() -> void:
			if _dragging:
				release_focus()
	)
	editing_toggled.connect(
		func(editing: bool) -> void:
			if editing:
				_value_before_edit = value
	)


func _get_drag_delta(p_event: InputEventMouse) -> float:
	return (p_event.position - _drag_start_mouse_pos).x


func _notification(p_what: int) -> void:
	if p_what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if _dragging and _drag_threshold_passed:
			_dragging = false
			float_submitted.emit(value)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_viewport().warp_mouse(get_global_rect().get_center())


func _input(p_event: InputEvent) -> void:
	if p_event is InputEventKey:
		if p_event.keycode == KEY_ESCAPE && p_event.pressed:
			if has_focus() and _is_editing:
				if _cache_valid:
					_cache_valid = false
					value = _value_cache
				elif text.strip_edges().is_empty():
					value = _value_before_edit
			release_focus()  # and emit submit
			if _dragging:
				_dragging = false
				value = _value_before_edit
				float_submitted.emit(value)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				get_viewport().warp_mouse(get_global_rect().get_center())

	const DRAG_THRESHOLD = 20.0  # pixels
	if _dragging and p_event is InputEventMouseMotion:
		_drag_mouse_total += p_event.relative
		var delta := _get_drag_delta(p_event)
		if abs(delta) > DRAG_THRESHOLD or _drag_threshold_passed:
			_drag_threshold_passed = true
			release_focus()
			const POWER := 1.1
			var t: float = sign(_drag_mouse_total.x) * pow(abs(_drag_mouse_total.x), POWER)
			value = _drag_start_value + round(t) * step
			float_edited.emit(value)
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	elif p_event is InputEventMouseButton:
		if p_event.button_index == MOUSE_BUTTON_LEFT:
			if p_event.pressed:
				if not is_editing() and not _dragging and get_global_rect().has_point(p_event.position):
					_value_before_edit = value
					_dragging = true
					release_focus()
					accept_event()

					_drag_start_mouse_pos = p_event.position
					_drag_mouse_total = Vector2.ZERO
					_drag_start_value = value
					_drag_threshold_passed = false
			else:
				if _dragging:
					accept_event()
					_dragging = false
					if _drag_threshold_passed:
						float_submitted.emit(value)
						Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
						get_viewport().warp_mouse(get_global_rect().get_center())
					else:
						grab_focus()
						select_all()


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


func set_max(p_max: float) -> void:
	self.max_value = p_max
	allow_greater = false
	value = min(value, p_max)


func set_min(p_min: float) -> void:
	self.min_value = p_min
	allow_lesser = false
	value = max(value, p_min)


func _clamp(p_value: float) -> float:
	if not allow_greater and p_value > max_value:
		return max_value
	if not allow_lesser and p_value < min_value:
		return min_value
	return p_value


func _get_closest_step(p_value: float) -> float:
	if step <= 0.0:
		return p_value
	var steps: float = round(p_value / step)
	return steps * step
