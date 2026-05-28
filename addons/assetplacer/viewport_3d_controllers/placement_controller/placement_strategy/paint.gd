# paint.gd
# © Copyright CookieBadger 2026
@tool
extends "res://addons/assetplacer/viewport_3d_controllers/placement_controller/placement_strategy/strategy.gd"

const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const SpatialUtils = preload("res://addons/assetplacer/utils/spatial_utils.gd")
const Editor3DViewportUtils = preload("res://addons/assetplacer/utils/editor_3d_viewport_utils.gd")
const SquareSnapping = preload("res://addons/assetplacer/viewport_3d_controllers/snapping_strategy/square.gd")

var snapping_state: AssetPlacerState.SnappingState:
	get():
		return AssetPlacerState.instance.snapping_state

var palette_state: AssetPlacerState.PaletteState:
	get():
		return AssetPlacerState.instance.palette_state

var _painted_nodes: Array[Node3D] = []
var _painting_prototype: Node3D = null
var _spawn_parent: Node = null
var _ray_strategy: RayStrategy = null
var _last_painting_asset_mouse_pos: Vector2 = -Vector2.ONE
var _last_painting_asset_pos: Vector3 = Vector3.INF
var _transformer: Transformer = null


# override
func begin_drag(
	_p_viewport: SubViewport,
	_p_asset: Asset3DData,
	p_prototype: Node3D,
	p_spawn_parent: Node,
	p_ray_strategy: RayStrategy,
	_p_first_ray_info: RayInfo,
	p_transformer: Transformer,
	p_first_transform: Transform3D,
	p_tip_key: String
) -> bool:
	_reset()
	_painting_prototype = p_prototype
	_spawn_parent = p_spawn_parent
	_transformer = p_transformer
	_ray_strategy = p_ray_strategy
	if not _is_position_occupied_with_same_node(p_prototype, p_spawn_parent, p_first_transform, _get_selected_asset_mesh_path(), p_tip_key):
		_place_copy(p_first_transform)
		Tips.set_tt(p_tip_key + "[child_test]", Lang.ttr("paint_begin"), Tips.TYPE.HINT)
	else:
		Tips.set_tt(p_tip_key, Lang.ttr("pos_occ"), Tips.TYPE.DEFAULT)

	return true


# override
func end_drag() -> Node3DList:
	var placed_nodelist := Node3DList.new(_painted_nodes)
	_reset()
	return placed_nodelist


# override
func drag(p_viewport: SubViewport, p_mouse_pos: Vector2, p_tip_key: String) -> void:
	if not _spawn_parent or not _spawn_parent.is_inside_tree():
		return

	if not snapping_state.is_active:
		return

	if p_mouse_pos == _last_painting_asset_mouse_pos:
		return

	var ray_info := RayInfo.invalid(RayInfo.VALIDITY.NO_INTERSECTION)
	var position_valid := false
	_last_painting_asset_mouse_pos = p_mouse_pos
	ray_info = _ray_strategy.get_placement(p_viewport.get_camera_3d(), p_mouse_pos, _painted_nodes)
	position_valid = ray_info.is_valid()
	if position_valid:
		AssetPlacerState.instance.placement_state.last_valid_ray_info = ray_info
		_ray_strategy.get_placement_plane(ray_info)
		ray_info.pos = SquareSnapping.snap_pos_with_offset(ray_info.pos, ray_info.normal, snapping_state.current_step, snapping_state.offset)
		if _painted_nodes.size() == 0 or ray_info.pos != _last_painting_asset_pos:
			_last_painting_asset_pos = ray_info.pos  # don't check same position twice
			var is_unique_pos := _painted_nodes.all(func(a: Node3D) -> bool: return not SpatialUtils.are_vecs_equal_approx(a.global_transform.origin, ray_info.pos))
			if is_unique_pos:
				var final_transform := _transformer.get_transform(ray_info)

				if not _is_position_occupied_with_same_node(_painting_prototype, _spawn_parent, final_transform, _get_selected_asset_mesh_path(), p_tip_key):
					_place_copy(final_transform)
					if _painted_nodes.size() <= 1:
						Tips.set_tt(p_tip_key + "[child_test]", Lang.ttr("paint_begin"), Tips.TYPE.HINT)
					else:
						Tips.set_tt(p_tip_key + "[child_test]", Lang.ttr("paint_continue") % _painted_nodes.size(), Tips.TYPE.VALUE)
				else:
					Tips.set_tt(p_tip_key, Lang.ttr("pos_occ"), Tips.TYPE.DEFAULT)


func _place_copy(p_transform: Transform3D) -> void:
	var duplicate := _painting_prototype.duplicate()
	_painted_nodes.push_back(duplicate)
	_spawn_parent.add_child(duplicate)
	duplicate.global_transform = p_transform
	AssetPlacerState.instance.placement_state.notify_placement(duplicate)


func _reset() -> void:
	_ray_strategy = null
	_painted_nodes.clear()
	_painting_prototype = null
	_spawn_parent = null
	_last_painting_asset_mouse_pos = -Vector2.ONE
	_last_painting_asset_pos = Vector3.INF
	_transformer = null


func _is_position_occupied_with_same_node(p_node: Node3D, p_spawn_parent: Node, p_node_transform_global: Transform3D, p_mesh_path: String, p_tip_key: String) -> bool:
	var children := p_spawn_parent.get_children()
	var placeholder: Node3D = Node3D.new()
	p_spawn_parent.add_child(placeholder)
	placeholder.global_transform = p_node_transform_global
	children.erase(placeholder)
	var placement_local_transform := placeholder.transform
	placeholder.free()

	const MAX_CHILD_CHECK_COUNT = 1000  # at this point, other processes get so slow, that this should not matter
	if children.size() > MAX_CHILD_CHECK_COUNT:
		Tips.set_tt(p_tip_key + "/child_test", Lang.ttr("child_exc"), Tips.TYPE.ERROR)
		children = children.slice(children.size() - MAX_CHILD_CHECK_COUNT, children.size())
	else:
		Tips.clear_tt(p_tip_key + "/child_test")

	# iterate over all children of node's parent to check if their position is equal to that of node
	for child in children:
		if child is Node3D:
			# checking local transform is sufficient, since they have the same parent
			# ToDo[AdvancedPaintMode]: test if precision is really enough. Maybe add a project setting to turn this stuff on and off
			if SpatialUtils.are_xforms_equal_approx(child.transform, placement_local_transform):
				# same asset
				if p_mesh_path:
					return child is MeshInstance3D && child.mesh.resource_path == p_mesh_path
				return child.scene_file_path == p_node.scene_file_path

	return false


func _get_selected_asset_mesh_path() -> String:
	if palette_state.selected_asset != null and palette_state.selected_asset.is_mesh:
		return palette_state.selected_asset.path
	return ""
