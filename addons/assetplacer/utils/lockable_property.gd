@tool
var _property_state: Variant
var _locked: bool = false
var _state_before_lock: Variant


func _init(initial_state: Variant = null) -> void:
	_property_state = initial_state
	_state_before_lock = initial_state


func set_state(p_state: Variant) -> void:
	_property_state = p_state
	if not _locked:
		_state_before_lock = p_state


func get_state() -> Variant:
	return _state_before_lock if _locked else _property_state


func lock(p_lock: bool) -> void:
	_locked = p_lock
