# surface_align_config_ui.gd
# © Copyright CookieBadger 2026
@tool
extends Control

const UIRegistry = preload("res://addons/assetplacer/ui_registry.gd")
const SpatialUtils = preload("res://addons/assetplacer/utils/spatial_utils.gd")

signal alignment_changed(enabled: bool, axis: int)

@export var _align_to_surface_normal_checkbox: CheckBox
@export var _alignment_direction_option_button: OptionButton

var axis: int:
	get:
		return _alignment_direction_option_button.selected
	set(value):
		if value < 0 or value >= _alignment_direction_option_button.item_count:
			return
		axis = value
		_alignment_direction_option_button.select(value)

var enabled: bool:
	get:
		return _align_to_surface_normal_checkbox.button_pressed
	set(value):
		enabled = value
		_align_to_surface_normal_checkbox.set_pressed_no_signal(value)


func initialize() -> void:
	_alignment_direction_option_button.clear()
	for axis_id: int in SpatialUtils.ALIGN_AXES.keys():
		_alignment_direction_option_button.add_item(SpatialUtils.ALIGN_AXES[axis_id], axis_id)

	_align_to_surface_normal_checkbox.toggled.connect(func(_b: bool) -> void: _alignment_changed())
	_alignment_direction_option_button.item_selected.connect(func(_idx: int) -> void: _alignment_changed())


func register_nodes() -> void:
	UIRegistry.register(UIRegistry.PLACEMENTCONFIG_ALIGN_TO_NORMAL_CHECKBOX, _align_to_surface_normal_checkbox)  # test automation access
	UIRegistry.register(UIRegistry.PLACEMENTCONFIG_ALIGNMENT_DIRECTION_OPTION_BUTTON, _alignment_direction_option_button)  # test automation access


func _alignment_changed() -> void:
	var align_axis: int = _alignment_direction_option_button.selected
	var is_enabled: bool = _align_to_surface_normal_checkbox.button_pressed
	assert(align_axis >= 0)
	alignment_changed.emit(is_enabled, align_axis)
