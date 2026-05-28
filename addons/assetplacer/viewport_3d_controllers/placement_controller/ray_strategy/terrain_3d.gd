# terrain_3d.gd
# © Copyright CookieBadger 2026
@tool
extends "res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/strategy.gd"

const SpatialUtils = preload("res://addons/assetplacer/utils/spatial_utils.gd")

const EPSILON := 1e-6


# override
func get_placement(p_camera: Camera3D, p_mouse_pos: Vector2, _p_placing_nodes: Array[Node3D]) -> RayInfo:
	var terrain_3d_node := AssetPlacerState.instance.placement_config_state.terrain_3d_node
	if p_camera == null:
		return RayInfo.invalid(RayInfo.VALIDITY.NO_INTERSECTION)
	print(terrain_3d_node)
	if terrain_3d_node == null:
		return RayInfo.invalid(RayInfo.VALIDITY.TERRAIN_ERROR, "no_terrain_node")
	var from := p_camera.project_ray_origin(p_mouse_pos)
	var dir := p_camera.project_ray_normal(p_mouse_pos)

	var data: Variant = get_terrain_3d_data(terrain_3d_node)
	if data == null:
		return RayInfo.invalid(RayInfo.VALIDITY.TERRAIN_ERROR, "terrain_data_err")

	var height_range: Vector2 = data.call("get_height_range")
	if height_range == null:
		height_range = data.get("height_range")  # legacy (>0.9.3)
		if height_range == null:
			return RayInfo.invalid(RayInfo.VALIDITY.TERRAIN_ERROR, "terrain_height_err")

	if p_camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		from = orthogonal_clamp(from, dir, height_range)

	var isec: Vector3 = terrain_3d_node.call("get_intersection", from, dir)
	if isec == null:
		return RayInfo.invalid(RayInfo.VALIDITY.TERRAIN_ERROR, "terrain_intersection_err")

	if isec.x >= 3.4e38:  # no intersection
		return RayInfo.invalid(RayInfo.VALIDITY.TERRAIN_NO_INTERSECTION, "terrain_no_intersection")

	var pos := isec
	var normal: Vector3 = data.call("get_normal", isec)
	if normal == null:
		return RayInfo.invalid(RayInfo.VALIDITY.TERRAIN_ERROR, "terrain_normal_err")

	if is_nan(normal.x) && is_nan(normal.y) && is_nan(normal.z):
		normal = Vector3.UP
	elif normal.length_squared() < EPSILON || is_nan(normal.x) || is_nan(normal.y) || is_nan(normal.z):
		return RayInfo.invalid(RayInfo.VALIDITY.TERRAIN_ERROR, "terrain_normal_err")

	var ray_info := RayInfo.new(pos, normal)

	#if RayInfo.is_valid():
	#	var (gridPos, gridRot) = get_grid_transform(ray_info)
	#	snapping.update_grid_transform(gridPos, camera.Projection == Camera3D.ProjectionType.Perspective, gridRot)

	#if RayInfo.is_valid():
	#	snapping.hide_grid(false)
	#return RayInfo.invalid(), $"{from}, {dir}, {intersection}", Colors.Red)
	return ray_info


func get_terrain_3d_data(p_terrain_3d_node: Node) -> Variant:
	if p_terrain_3d_node == null:
		return null

	if p_terrain_3d_node.get_property_list().any(func(d: Dictionary) -> bool: return d["name"] == "data"):
		return p_terrain_3d_node.get("data")
	if p_terrain_3d_node.has_method("get_data"):
		return p_terrain_3d_node.call("get_data")
	return null


func orthogonal_clamp(p_from: Vector3, p_dir: Vector3, p_height_range: Vector2) -> Vector3:
	const DISTANCE: int = 30
	if p_from.y > 1 && p_dir.y < 0:  # looking from above
		var m := p_height_range.y + DISTANCE
		var t := (m - p_from.y) / p_dir.y
		return p_from + p_dir * t
	if p_from.y < -1 && p_dir.y > 0:  # looking from below
		var m := p_height_range.x - DISTANCE
		var t := (m - p_from.y) / p_dir.y
		return p_from + p_dir * t
	return p_from


func rotate_node(p_node: Node3D, p_start_rotation: Vector3, p_rotation: float) -> void:
	if AssetPlacerState.instance.placement_state.last_valid_ray_info == null:
		return  # should not happen
	p_node.rotation = p_start_rotation
	p_node.global_rotate(AssetPlacerState.instance.placement_state.last_valid_ray_info.normal, p_rotation)
