# snapping_controller.gd
# © Copyright CookieBadger 2026
@tool
extends "res://addons/assetplacer/viewport_3d_controllers/viewport_3d_controller.gd"

const GridGizmo = preload("res://addons/assetplacer/gizmos/grid_gizmo.gd")
const RayInfo = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/ray_info.gd")
const SpatialUtils = preload("res://addons/assetplacer/utils/spatial_utils.gd")
const SquareSnapping = preload("res://addons/assetplacer/viewport_3d_controllers/snapping_strategy/square.gd")
const Settings = preload("res://addons/assetplacer/settings.gd")

const MAX_GRID_LINE_CNT := 10000
const SNAPPING_GRID_SETTING := "Snapping_Grid_Color"
const GRID_ALPHA_PRIMARY := 0.33
const GRID_ALPHA_SECONDARY := 0.08
const DEFAULT_GRID_COLOR := Color("4c8d90")

var snapping_state: AssetPlacerState.SnappingState:
	get:
		return AssetPlacerState.instance.snapping_state

var mode_grid_length: Dictionary[AssetPlacerState.PlacementConfigState.RayMode, int] = {
	AssetPlacerState.PlacementConfigState.RayMode.PHYSICS_SURFACE: 40,
	AssetPlacerState.PlacementConfigState.RayMode.PLANE: 400,
	AssetPlacerState.PlacementConfigState.RayMode.TERRAIN_3D: 40,
}

var _grid_gizmo: GridGizmo
var _secondary_grid_gizmo: GridGizmo


func initialize() -> void:
	snapping_state.step_changed.connect(func(_v: float) -> void: _update_primary_grid_spacing())
	snapping_state.offset_changed.connect(func(_v: Vector2) -> void: _update_primary_grid_spacing())
	snapping_state.shift_step_changed.connect(func(_v: float) -> void: _update_secondary_grid_spacing())
	snapping_state.offset_changed.connect(func(_v: Vector2) -> void: _update_secondary_grid_spacing())
	snapping_state.enabled_changed.connect(func(_b: bool) -> void: update_grid())
	Settings.register_setting(Settings.DEFAULT_CATEGORY, SNAPPING_GRID_SETTING, DEFAULT_GRID_COLOR, TYPE_COLOR)
	ProjectSettings.settings_changed.connect(update_grid)
	update_grid()
	AssetPlacerState.instance.scene_changed.connect(update_grid)
	InputManager.instance.vp_input.connect(_on_vp_input)
	AssetPlacerState.instance.snapping_state.grid_ray_info_changed.connect(func(_i: RayInfo) -> void: update_and_move_grids())


func cleanup() -> void:
	free_grid_gizmo()
	free_secondary_grid_gizmo()


func _on_vp_input() -> void:
	if InputManager.instance.shift_pressed:
		snapping_state.current_step = snapping_state.shift_step
	else:
		snapping_state.current_step = snapping_state.step
	snapping_state.toggled = InputManager.instance.ctrl_pressed


func update_and_move_grids() -> void:
	update_grid()
	move_grids()


func move_grids() -> void:
	if snapping_state.grid_ray_info == null or not snapping_state.grid_ray_info.is_valid():
		return

	var pos := snapping_state.grid_ray_info.pos
	var rot := SpatialUtils.get_vector_rotation(Vector3.UP, snapping_state.grid_ray_info.normal).get_euler()
	if _grid_gizmo and _grid_gizmo.is_inside_tree():
		var snap_pos := SquareSnapping.snap_pos_with_offset(pos, snapping_state.grid_ray_info.normal, snapping_state.step, snapping_state.offset)
		_grid_gizmo.global_position = snap_pos
		_grid_gizmo.global_rotation = rot

	if _secondary_grid_gizmo and _secondary_grid_gizmo.is_inside_tree():
		var snap_pos := SquareSnapping.snap_pos_with_offset(pos, snapping_state.grid_ray_info.normal, snapping_state.shift_step, snapping_state.offset)
		_secondary_grid_gizmo.global_position = snap_pos
		_secondary_grid_gizmo.global_rotation = rot


func update_grid() -> void:
	initialize_gizmos_if_invalid()
	var grid_placement_valid := snapping_state.grid_ray_info != null and snapping_state.grid_ray_info.is_valid()
	var display_secondary: bool = InputManager.instance.shift_pressed and AssetPlacerState.instance.snapping_state.grid_input_active
	if _grid_gizmo:
		_grid_gizmo.visible = snapping_state.is_active and not display_secondary and grid_placement_valid
	if _secondary_grid_gizmo:
		_secondary_grid_gizmo.visible = snapping_state.is_active and display_secondary and grid_placement_valid


func _update_primary_grid_spacing() -> void:
	_update_grid_spacing(_grid_gizmo, snapping_state.step, _get_grid_color())
	move_grids()


func _update_secondary_grid_spacing() -> void:
	_update_grid_spacing(_secondary_grid_gizmo, snapping_state.shift_step, _get_grid_color(false))
	move_grids()


func _get_grid_color(primary: bool = true) -> Color:
	var color: Color = Settings.get_setting(Settings.DEFAULT_CATEGORY, SNAPPING_GRID_SETTING)
	color.a = GRID_ALPHA_PRIMARY if primary else GRID_ALPHA_SECONDARY
	return color


func _update_grid_spacing(grid: Variant, step: float, color: Color) -> void:
	# grid might be invalid (e.g. if scene was changed)
	if grid is GridGizmo:
		grid.line_spacing = step
		grid.line_cnt = min(mode_grid_length[AssetPlacerState.instance.placement_config_state.ray_mode] / step, MAX_GRID_LINE_CNT)
		grid.create_mesh(color)


func initialize_gizmos_if_invalid() -> void:
	var scene_root := EditorInterface.get_edited_scene_root()
	if not scene_root:
		return

	if _grid_gizmo != null and not _grid_gizmo.is_inside_tree():
		free_grid_gizmo()

	if _secondary_grid_gizmo != null and not _secondary_grid_gizmo.is_inside_tree():
		free_secondary_grid_gizmo()

	if _grid_gizmo == null:
		_grid_gizmo = create_gizmo(scene_root)
		_update_primary_grid_spacing()
	elif _grid_gizmo.get_color() != _get_grid_color():
		_grid_gizmo.set_color(_get_grid_color())

	if _secondary_grid_gizmo == null:
		_secondary_grid_gizmo = create_gizmo(scene_root)
		_update_secondary_grid_spacing()
	elif _secondary_grid_gizmo.get_color() != _get_grid_color(false):
		_secondary_grid_gizmo.set_color(_get_grid_color(false))


func create_gizmo(root: Node) -> GridGizmo:
	var gizmo := GridGizmo.new()
	root.add_child(gizmo)
	gizmo.tree_exited.connect(func() -> void: gizmo.queue_free())
	return gizmo


func free_grid_gizmo() -> void:
	if _grid_gizmo:
		_grid_gizmo.queue_free()
		_grid_gizmo = null


func free_secondary_grid_gizmo() -> void:
	if _secondary_grid_gizmo:
		_secondary_grid_gizmo.queue_free()
		_secondary_grid_gizmo = null

# # override
# func forward_3d_viewport_input(viewport: SubViewport, event: InputEvent, action: InputManager.ActionType) -> void:
# 	var show_grid : bool = snapping_state.is_active
# 	show_grid(show_grid)
