# snapping_config_view.gd
# © Copyright CookieBadger 2026
@tool
extends Control

const FloatEditorLineEdit = preload("res://addons/assetplacer/ui/components/float_editor_line_edit.gd")
const RangeEditorLineEdit = preload("res://addons/assetplacer/ui/components/range_editor_line_edit.gd")
const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const SnappingConfigController = preload("res://addons/assetplacer/ui/snapping_config_ui/snapping_config_controller.gd")
const ThemeBuilder = preload("res://addons/assetplacer/ui/theme_builder.gd")
const UIRegistry = preload("res://addons/assetplacer/ui_registry.gd")

signal reset_offset
signal offset_from_selected

signal snap_step_submitted(snap_step: float)
signal config_edit(enabled: bool, snap_step: float, shift_snap_step: float, offset_a: float, offset_b: float)
signal config_edit_preview(enabled: bool, snap_step: float, shift_snap_step: float, offset_a: float, offset_b: float)

@export var _offset_from_selected_button: Button
@export var _reset_offset_button: Button
@export var _enabled_checkbox: CheckBox
@export var _snap_step_edit: RangeEditorLineEdit
@export var _shift_snap_step_edit: RangeEditorLineEdit
@export var _offset_a_edit: RangeEditorLineEdit
@export var _offset_b_edit: RangeEditorLineEdit


func initialize() -> void:
	_reset_offset_button.pressed.connect(reset_offset.emit)
	_offset_from_selected_button.pressed.connect(offset_from_selected.emit)
	_enabled_checkbox.toggled.connect(func(_enabled: bool) -> void: _on_edit())

	_snap_step_edit.float_edited.connect(func(_v: float) -> void: _on_edit_preview())
	_shift_snap_step_edit.float_edited.connect(func(_v: float) -> void: _on_edit_preview())
	_offset_a_edit.float_edited.connect(func(_v: float) -> void: _on_edit_preview())
	_offset_b_edit.float_edited.connect(func(_v: float) -> void: _on_edit_preview())

	_snap_step_edit.set_min(SnappingConfigController.MIN_SNAP_STEP)
	_shift_snap_step_edit.set_min(SnappingConfigController.MIN_SNAP_STEP)
	_snap_step_edit.float_submitted.connect(func(_v: float) -> void: _on_snap_step_edit())
	_shift_snap_step_edit.float_submitted.connect(func(_v: float) -> void: _on_edit())
	_offset_a_edit.float_submitted.connect(func(_v: float) -> void: _on_edit())
	_offset_b_edit.float_submitted.connect(func(_v: float) -> void: _on_edit())

	AssetPlacerState.instance.snapping_state.enabled_changed.connect(func(b: bool) -> void: _enabled_checkbox.button_pressed = b)
	AssetPlacerState.instance.snapping_state.step_changed.connect(
		func(v: float) -> void:
			_snap_step_edit.value = v
			_update_shift_step_theme()
	)
	AssetPlacerState.instance.snapping_state.shift_step_changed.connect(
		func(v: float) -> void:
			_shift_snap_step_edit.value = v
			_update_shift_step_theme()
	)
	AssetPlacerState.instance.snapping_state.offset_changed.connect(
		func(v: Vector2) -> void:
			_offset_a_edit.value = v.x
			_offset_b_edit.value = v.y
	)

	_on_selection_changed()
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)

	_setup_icons()
	EditorInterface.get_base_control().theme_changed.connect(_setup_icons)


func register_nodes() -> void:  # test automation access
	UIRegistry.register(UIRegistry.SNAPPING_ENABLED_CHECKBOX, _enabled_checkbox)
	UIRegistry.register(UIRegistry.SNAPPING_SNAP_STEP_EDIT, _snap_step_edit)
	UIRegistry.register(UIRegistry.SNAPPING_SHIFT_SNAP_STEP_EDIT, _shift_snap_step_edit)
	UIRegistry.register(UIRegistry.SNAPPING_OFFSET_A_EDIT, _offset_a_edit)
	UIRegistry.register(UIRegistry.SNAPPING_OFFSET_B_EDIT, _offset_b_edit)
	UIRegistry.register(UIRegistry.SNAPPING_OFFSET_FROM_SELECTED_BUTTON, _offset_from_selected_button)
	UIRegistry.register(UIRegistry.SNAPPING_RESET_OFFSET_BUTTON, _reset_offset_button)


func _update_shift_step_theme() -> void:
	if not _snap_step_edit.is_editing_or_dragging():
		if is_equal_approx(AssetPlacerState.instance.snapping_state.shift_step, AssetPlacerState.instance.snapping_state.step * SnappingConfigController.DEFAULT_SHIFT_SNAP_STEP_FACTOR):
			_shift_snap_step_edit.theme_type_variation = "GreyedRaisedButton"
		else:
			_shift_snap_step_edit.theme_type_variation = "RaisedButton"


func _on_snap_step_edit() -> void:
	snap_step_submitted.emit(_snap_step_edit.value)
	_update_shift_step_theme()


func _on_edit() -> void:
	config_edit.emit(_enabled_checkbox.button_pressed, _snap_step_edit.value, _shift_snap_step_edit.value, _offset_a_edit.value, _offset_b_edit.value)


func _on_edit_preview() -> void:
	config_edit_preview.emit(_enabled_checkbox.button_pressed, _snap_step_edit.value, _shift_snap_step_edit.value, _offset_a_edit.value, _offset_b_edit.value)


func _on_selection_changed() -> void:
	var selected_nodes := EditorInterface.get_selection().get_selected_nodes()
	_offset_from_selected_button.disabled = selected_nodes.size() != 1 or not selected_nodes[0] is Node3D


func _setup_icons() -> void:
	var bc := EditorInterface.get_base_control()
	_offset_from_selected_button.text = ""
	_offset_from_selected_button.icon = bc.get_theme_icon("EditorPositionUnselected", "EditorIcons")
	_reset_offset_button.text = ""
	_reset_offset_button.icon = bc.get_theme_icon("Reload", "EditorIcons")
