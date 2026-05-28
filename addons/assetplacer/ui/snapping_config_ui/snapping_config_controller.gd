# snapping_config_controller.gd
# © Copyright CookieBadger 2026
@tool
extends Node

const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const SnappingConfigView = preload("res://addons/assetplacer/ui/snapping_config_ui/snapping_config_view.gd")
const AssetPlacerPersistence = preload("res://addons/assetplacer/assetplacer_persistence.gd")
const SquareSnapping = preload("res://addons/assetplacer/viewport_3d_controllers/snapping_strategy/square.gd")

const MIN_SNAP_STEP := 0.001
const DEFAULT_SHIFT_SNAP_STEP_FACTOR := 0.1

var snapping_state: AssetPlacerState.SnappingState:
	get:
		return AssetPlacerState.instance.snapping_state


func initialize(view: SnappingConfigView) -> void:
	load_data()
	view.config_edit_preview.connect(_on_config_edit_preview)
	view.config_edit.connect(_on_config_edited)
	view.snap_step_submitted.connect(
		func(snap_step: float) -> void: _on_config_edited(snapping_state.enabled, snap_step, snap_step * DEFAULT_SHIFT_SNAP_STEP_FACTOR, snapping_state.offset.x, snapping_state.offset.y)
	)
	view.reset_offset.connect(_on_offset_reset)
	view.offset_from_selected.connect(_on_offset_from_selected)
	AssetPlacerState.instance.scene_changed.connect(on_scene_changed)
	snapping_state.enabled_changed.connect(func(_e: bool) -> void: AssetPlacerPersistence.instance.store_scene_data(snapping_state.ENABLED_SAVE_KEY, snapping_state.enabled))
	snapping_state.step_changed.connect(func(_s: float) -> void: AssetPlacerPersistence.instance.store_scene_data(snapping_state.SNAP_STEP_SAVE_KEY, snapping_state.step))
	snapping_state.shift_step_changed.connect(func(_s: float) -> void: AssetPlacerPersistence.instance.store_scene_data(snapping_state.SNAP_STEP_SHIFT_SAVE_KEY, snapping_state.shift_step))
	snapping_state.offset_changed.connect(func(_o: Vector2) -> void: AssetPlacerPersistence.instance.store_scene_data(snapping_state.GRID_OFFSET_SAVE_KEY, snapping_state.offset))


func cleanup() -> void:
	pass


func _on_config_edit_preview(enabled: bool, snap_step: float, shift_snap_step: float, offset_a: float, offset_b: float) -> void:
	snapping_state.enabled = enabled
	snapping_state.step = snap_step
	snapping_state.shift_step = shift_snap_step
	snapping_state.offset = Vector2(offset_a, offset_b)


func _on_config_edited(enabled: bool, snap_step: float, shift_snap_step: float, offset_a: float, offset_b: float) -> void:
	snapping_state.enabled = enabled
	snapping_state.step = _validate_snap_step(snap_step)
	snapping_state.shift_step = _validate_shift_snap_step(shift_snap_step, snapping_state.step)
	snapping_state.offset = Vector2(offset_a, offset_b)


func on_scene_changed() -> void:
	load_data()


func load_data() -> void:
	# load all values first before modifying any, to avoid loading an overriden dependent value
	var loaded_step := _validate_snap_step(AssetPlacerPersistence.instance.load_scene_data(snapping_state.SNAP_STEP_SAVE_KEY, 1.0, TYPE_FLOAT))
	var loaded_shift_step: float = AssetPlacerPersistence.instance.load_scene_data(snapping_state.SNAP_STEP_SHIFT_SAVE_KEY, 0.1, TYPE_FLOAT)
	var loaded_offset: Vector2 = AssetPlacerPersistence.instance.load_scene_data(snapping_state.GRID_OFFSET_SAVE_KEY, Vector2.ZERO, TYPE_VECTOR2)
	var loaded_enabled: bool = AssetPlacerPersistence.instance.load_scene_data(snapping_state.ENABLED_SAVE_KEY, false, TYPE_BOOL)
	snapping_state.enabled = loaded_enabled
	snapping_state.step = loaded_step
	snapping_state.shift_step = _validate_shift_snap_step(loaded_shift_step, snapping_state.step)
	snapping_state.offset = loaded_offset


func _on_offset_reset() -> void:
	snapping_state.offset = Vector2.ZERO
	AssetPlacerPersistence.instance.store_scene_data(snapping_state.GRID_OFFSET_SAVE_KEY, Vector2.ZERO)


func _on_offset_from_selected() -> void:
	var sel := EditorInterface.get_selection().get_selected_nodes()
	if sel.size() == 0 or not sel[0] is Node3D:
		printerr("AssetPlacer: No valid node selected for offsetting snapping grid.")
		return
	var global_pos: Vector3 = sel[0].global_position

	var placement_plane := AssetPlacerState.instance.placement_state.current_placement_plane
	if not placement_plane or not placement_plane.is_valid():
		printerr("AssetPlacer: No valid ray info available. Try hovering over the surface you want to place on first.")
		return

	var offset := SquareSnapping.get_translate_offset_from_position(global_pos, placement_plane.pos, placement_plane.normal, snapping_state.step)
	_on_config_edited(snapping_state.enabled, snapping_state.step, snapping_state.shift_step, offset.x, offset.y)


func _validate_snap_step(v: float) -> float:
	return abs(v) if abs(v) >= MIN_SNAP_STEP else 1.0


func _validate_shift_snap_step(v: float, step: float) -> float:
	return abs(v) if abs(v) >= MIN_SNAP_STEP else step * DEFAULT_SHIFT_SNAP_STEP_FACTOR
