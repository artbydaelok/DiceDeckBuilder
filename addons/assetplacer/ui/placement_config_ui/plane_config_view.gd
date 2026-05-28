# plane_config_view.gd
# © Copyright CookieBadger 2026
@tool
extends Control

const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const AssetPlacerPlugin = preload("res://addons/assetplacer/assetplacer_plugin.gd")
const FloatEditorLineEdit = preload("res://addons/assetplacer/ui/components/float_editor_line_edit.gd")
const RangeEditorLineEdit = preload("res://addons/assetplacer/ui/components/range_editor_line_edit.gd")
const UIRegistry = preload("res://addons/assetplacer/ui_registry.gd")
const PlacementPlane = AssetPlacerState.PlacementConfigState.PlacementPlane

signal plane_selected(plane: PlacementPlane)
signal position_edited(position: float)
signal position_submitted(position: float)

signal position_from_selected
signal reset_position

@export var _plane_option_button: OptionButton
@export var _plane_position_line_edit: RangeEditorLineEdit
@export var _position_from_selected_button: Button
@export var _reset_position_button: Button


func initialize() -> void:
	_plane_option_button.clear()
	for i: String in PlacementPlane.keys():
		_plane_option_button.add_item(i)
	_plane_option_button.item_selected.connect(func(_idx: bool) -> void: plane_selected.emit(_get_plane()))

	_plane_position_line_edit.float_edited.connect(position_edited.emit)
	_plane_position_line_edit.float_submitted.connect(position_submitted.emit)

	_position_from_selected_button.pressed.connect(position_from_selected.emit)
	_reset_position_button.pressed.connect(reset_position.emit)

	AssetPlacerState.instance.placement_config_state.plane_changed.connect(
		func(p: PlacementPlane) -> void:
			if p != _get_plane():
				_plane_position_line_edit.exit_edit()  # avoid update conflict
			_update_view()
	)
	AssetPlacerState.instance.placement_config_state.plane_positions_changed.connect(func(_p: Array[float]) -> void: _update_view())

	_on_selection_changed()
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	_setup_icons()
	EditorInterface.get_base_control().theme_changed.connect(_setup_icons)


func register_nodes() -> void:  # test automation access
	UIRegistry.register(UIRegistry.PLACEMENTCONFIG_PLANE_OPTION_BUTTON, _plane_option_button)
	UIRegistry.register(UIRegistry.PLACEMENTCONFIG_PLANE_POSITION_LINE_EDIT, _plane_position_line_edit)
	UIRegistry.register(UIRegistry.PLACEMENTCONFIG_POSITION_FROM_SELECTED_BUTTON, _position_from_selected_button)
	UIRegistry.register(UIRegistry.PLACEMENTCONFIG_RESET_POSITION_BUTTON, _reset_position_button)


func _on_selection_changed() -> void:
	var selected_nodes := EditorInterface.get_selection().get_selected_nodes()
	_position_from_selected_button.disabled = selected_nodes.size() != 1 or not selected_nodes[0] is Node3D


func _setup_icons() -> void:
	var bc := EditorInterface.get_base_control()
	_position_from_selected_button.text = ""
	_position_from_selected_button.icon = bc.get_theme_icon("EditorPositionUnselected", "EditorIcons")
	_reset_position_button.text = ""
	_reset_position_button.icon = bc.get_theme_icon("Reload", "EditorIcons")


func _update_view() -> void:
	_plane_option_button.selected = int(AssetPlacerState.instance.placement_config_state.plane)
	_set_plane_pos_text(AssetPlacerState.instance.placement_config_state.plane_position)


func _set_plane_pos_text(p_pos: float) -> void:
	_plane_position_line_edit.value = AssetPlacerPlugin.round_to_ui_decimals(p_pos)


func _get_plane() -> PlacementPlane:
	var s := _plane_option_button.selected
	assert(s >= 0 and s < PlacementPlane.keys().size())
	return _plane_option_button.selected as PlacementPlane
