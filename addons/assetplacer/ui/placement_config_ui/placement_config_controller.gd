# placement_config_controller.gd
# © Copyright CookieBadger 2026
@tool
extends Node

const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const PlacementConfigUI = preload("res://addons/assetplacer/ui/placement_config_ui/placement_config_ui.gd")
const AssetPlacerPersistence = preload("res://addons/assetplacer/assetplacer_persistence.gd")
const RayMode = AssetPlacerState.PlacementConfigState.RayMode

const RAY_MODE_STRINGS: Dictionary[String, RayMode] = {"Plane": RayMode.PLANE, "Surface": RayMode.PHYSICS_SURFACE, "Terrain3D": RayMode.TERRAIN_3D, "Dummy": RayMode.DUMMY}

var ui: PlacementConfigUI

var placement_config_state: AssetPlacerState.PlacementConfigState:
	get:
		return AssetPlacerState.instance.placement_config_state


func initialize(p_ui: PlacementConfigUI) -> void:
	placement_config_state.ray_mode_changed.connect(_on_ray_mode_changed)
	ui = p_ui
	ui.mode_selected.connect(_on_mode_selected)
	ui.spawn_parent_selected.connect(_on_spawn_parent_selected)
	ui.plane_config_view.plane_selected.connect(func(p: AssetPlacerState.PlacementConfigState.PlacementPlane) -> void: _on_plane_config_view_changed(p, placement_config_state.plane_positions))
	ui.plane_config_view.position_edited.connect(_on_plane_position_edited)
	ui.plane_config_view.position_submitted.connect(_on_plane_position_edited)
	ui.plane_config_view.reset_position.connect(_on_plane_pos_reset)
	ui.plane_config_view.position_from_selected.connect(_on_plane_position_from_selected)
	ui.surface_config_view.config_changed.connect(_on_surface_config_view_changed)
	ui.terrain_3d_config_view.config_changed.connect(_on_terrain_3d_config_view_changed)
	ui.terrain_3d_config_view.terrain3d_selector.initialize(placement_config_state.TERRAIN_3D_NODE_SAVE_KEY)
	ui.spawn_parent_selection.initialize(placement_config_state.SPAWN_PARENT_SAVE_KEY)
	AssetPlacerState.instance.scene_changed.connect(on_scene_changed)
	load_data()


func cleanup() -> void:
	pass


func _on_plane_pos_reset() -> void:
	var m_pos := _modified_positions(placement_config_state.plane, 0.0)
	_on_plane_config_view_changed(placement_config_state.plane, m_pos)


func _on_plane_position_from_selected() -> void:
	var sel := EditorInterface.get_selection().get_selected_nodes()
	if sel.size() == 0 or not sel[0] is Node3D:
		return
	var global_pos: Vector3 = sel[0].global_position

	var val: float
	match placement_config_state.plane:
		AssetPlacerState.PlacementConfigState.PlacementPlane.XY:
			val = global_pos.z
		AssetPlacerState.PlacementConfigState.PlacementPlane.XZ:
			val = global_pos.y
		AssetPlacerState.PlacementConfigState.PlacementPlane.YZ:
			val = global_pos.x
	var m_pos := _modified_positions(placement_config_state.plane, val)
	_on_plane_config_view_changed(placement_config_state.plane, m_pos)


func _on_mode_selected(mode: RayMode) -> void:
	placement_config_state.ray_mode = mode


func _on_spawn_parent_selected(node: Node) -> void:
	assert(!node or EditorInterface.get_edited_scene_root().get_parent().is_ancestor_of(node))
	placement_config_state.spawn_parent_node = node


## unused, in case you want plane to flash twice, replace `position_submitted` above with `position_submitted.connect(_on_plane_position_submitted)`.
func _on_plane_position_submitted(val: float) -> void:
	_on_plane_position_edited(val)
	placement_config_state.plane_positions_changed.emit(placement_config_state.plane_positions)  # hack: trigger update, to make plane flash


func _on_plane_position_edited(val: float) -> void:
	var m_pos := _modified_positions(placement_config_state.plane, val)
	_on_plane_config_view_changed(placement_config_state.plane, m_pos)


func _modified_positions(plane: AssetPlacerState.PlacementConfigState.PlacementPlane, val: float) -> Array[float]:
	var positions: Array[float] = placement_config_state.plane_positions.duplicate()
	positions[int(plane)] = val
	return positions


func _on_ray_mode_changed(mode: RayMode) -> void:
	ui.set_view_visible(mode)
	AssetPlacerPersistence.instance.store_scene_data(placement_config_state.RAY_MODE_SAVE_KEY, get_ray_mode_string(mode))


func _on_plane_config_view_changed(plane: AssetPlacerState.PlacementConfigState.PlacementPlane, positions: Array[float]) -> void:
	placement_config_state.plane = plane
	placement_config_state.plane_positions = positions
	AssetPlacerPersistence.instance.store_scene_data(placement_config_state.PLACEMENT_PLANE_SAVE_KEY, plane)
	AssetPlacerPersistence.instance.store_scene_data(placement_config_state.PLANE_POSITIONS_SAVE_KEY, PackedFloat32Array(positions))


func _on_surface_config_view_changed(align_enabled: bool, align_axis: int) -> void:
	placement_config_state.surface_align_enabled = align_enabled
	placement_config_state.surface_align_axis = align_axis
	#placement_config_state.surface_normal_offset = offset
	AssetPlacerPersistence.instance.store_scene_data(placement_config_state.SURFACE_ALIGN_ENABLED_SAVE_KEY, align_enabled)
	AssetPlacerPersistence.instance.store_scene_data(placement_config_state.SURFACE_ALIGNMENT_AXIS_SAVE_KEY, align_axis)
	#AssetPlacerPersistence.instance.store_scene_data(placement_config_state.SURFACE_OFFSET, offset)


func _on_terrain_3d_config_view_changed(terrain_3d_node: Node) -> void:
	placement_config_state.terrain_3d_node = terrain_3d_node
	#placement_config_state.terrain_3d_normal_offset = offset
	AssetPlacerPersistence.instance.store_scene_data(placement_config_state.TERRAIN_3D_NODE_SAVE_KEY, EditorInterface.get_edited_scene_root().get_path_to(terrain_3d_node))


func on_scene_changed() -> void:
	load_data()


func load_data() -> void:
	var ray_mode_string: String = AssetPlacerPersistence.instance.load_scene_data(placement_config_state.RAY_MODE_SAVE_KEY, get_ray_mode_string(RayMode.PLANE), TYPE_STRING)
	if not RAY_MODE_STRINGS.has(ray_mode_string):
		ray_mode_string = RAY_MODE_STRINGS.keys()[0]

	var mode := RAY_MODE_STRINGS[ray_mode_string]

	if not ui.placement_option_button_has_item(mode):
		if RAY_MODE_STRINGS[ray_mode_string] == RayMode.TERRAIN_3D:
			push_warning("To Enable Terrain3D placement, make sure that the Terrain3D plugin is enabled in ProjectSettings.")

		mode = RayMode.PLANE

	placement_config_state.ray_mode = mode
	ui.set_view_visible(mode)

	var plane: int = AssetPlacerPersistence.instance.load_scene_data(placement_config_state.PLACEMENT_PLANE_SAVE_KEY, 1, TYPE_INT)
	placement_config_state.plane = plane as AssetPlacerState.PlacementConfigState.PlacementPlane
	var plane_positions: Array[float] = []
	plane_positions.assign(AssetPlacerPersistence.instance.load_scene_data(placement_config_state.PLANE_POSITIONS_SAVE_KEY, [0.0, 0.0, 0.0], TYPE_PACKED_FLOAT32_ARRAY))
	placement_config_state.plane_positions = plane_positions

	var surf_align: bool = AssetPlacerPersistence.instance.load_scene_data(placement_config_state.SURFACE_ALIGN_ENABLED_SAVE_KEY, false, TYPE_BOOL)
	placement_config_state.surface_align_enabled = surf_align

	var surf_align_axis: int = AssetPlacerPersistence.instance.load_scene_data(placement_config_state.SURFACE_ALIGNMENT_AXIS_SAVE_KEY, 2, TYPE_INT)
	placement_config_state.surface_align_axis = surf_align_axis

	if EditorInterface.get_edited_scene_root():
		var terrain_3d_node: NodePath = AssetPlacerPersistence.instance.load_scene_data(placement_config_state.TERRAIN_3D_NODE_SAVE_KEY, NodePath("."), TYPE_NODE_PATH)
		var node := EditorInterface.get_edited_scene_root().get_node_or_null(terrain_3d_node)
		if node and node.is_class("Terrain3D"):
			placement_config_state.terrain_3d_node = node
		else:
			placement_config_state.terrain_3d_node = null


static func get_ray_mode_string(mode: RayMode) -> String:
	var idx := RAY_MODE_STRINGS.keys().find_custom(func(m: String) -> bool: return RAY_MODE_STRINGS[m] == mode)
	if idx < 0:
		return "Dummy"
	return RAY_MODE_STRINGS.keys()[idx]
