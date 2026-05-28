# plane.gd
# © Copyright CookieBadger 2026
@tool
extends "res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/strategy.gd"

const Editor3DViewportUtils = preload("res://addons/assetplacer/utils/editor_3d_viewport_utils.gd")
const PlacementPlane = AssetPlacerState.PlacementConfigState.PlacementPlane

const EPSILON := 1e-4

var placement_config_state: AssetPlacerState.PlacementConfigState:
	get:
		return AssetPlacerState.instance.placement_config_state


static func get_plane_normal() -> Vector3:
	match AssetPlacerState.instance.placement_config_state.plane:
		PlacementPlane.XY:
			return Vector3.BACK
		PlacementPlane.XZ:
			return Vector3.UP
		PlacementPlane.YZ:
			return Vector3.RIGHT
	return Vector3.UP


static func get_plane_axis() -> int:
	match AssetPlacerState.instance.placement_config_state.plane:
		PlacementPlane.XY:
			return Vector3.AXIS_Z
		PlacementPlane.XZ:
			return Vector3.AXIS_Y
		PlacementPlane.YZ:
			return Vector3.AXIS_X
	return Vector3.AXIS_Y


func get_placement_plane(_p_last_ray_info: RayInfo) -> RayInfo:
	var pos := Vector3.ZERO
	pos[get_plane_axis()] = placement_config_state.plane_position
	return RayInfo.new(pos, get_plane_normal())


# override
func rotate_node(p_node: Node3D, p_start_rotation: Vector3, p_rotation: float) -> void:
	p_node.rotation = p_start_rotation
	var axis := get_plane_normal()
	p_node.global_rotate(axis, p_rotation)


# override
func get_placement(p_camera: Camera3D, p_mouse_pos: Vector2, _p_placing_nodes: Array[Node3D]) -> RayInfo:
	if p_camera == null:
		return RayInfo.invalid(RayInfo.VALIDITY.NO_INTERSECTION)

	var from := p_camera.project_ray_origin(p_mouse_pos)
	var dir := p_camera.project_ray_normal(p_mouse_pos)

	# check that dir is not parallel to plane (mouse ray has no intersection with plane)
	if dir[get_plane_axis()] != 0.0:
		var t: float = (placement_config_state.plane_position - from[get_plane_axis()]) / dir[get_plane_axis()]
		if t >= 0.0:  # if t < 0, the intersection is behind the camera
			var pos := from + t * dir

			if not is_placement_on_plane_horizon(dir, get_plane_axis(), p_camera.position, placement_config_state.plane_position, pos):
				return RayInfo.new(pos, get_plane_normal())

	return RayInfo.invalid(RayInfo.VALIDITY.NO_INTERSECTION)


# override
func get_grid_placement() -> RayInfo:
	var vp := Editor3DViewportUtils.get_focused_3d_viewport()
	if vp:
		var cam := vp.get_camera_3d()
		return RayInfo.new(calculate_plane_gizmo_pos(cam), get_plane_normal())

	var pos := Vector3.ZERO
	pos[get_plane_axis()] = placement_config_state.plane_position

	return RayInfo.new(pos, get_plane_normal())


func is_placement_on_plane_horizon(p_cam_look_direction: Vector3, p_plane_normal: int, p_cam_position: Vector3, p_plane_height: float, p_placement_position: Vector3) -> bool:
	var flat_cam_position := p_cam_position
	flat_cam_position[p_plane_normal] = p_plane_height

	var cam_angle := get_cam_plane_angle(p_cam_look_direction, p_plane_normal, p_plane_height)
	var dist_sq := (p_placement_position - flat_cam_position).length_squared()
	var cam_plane_distance: float = abs(p_cam_position[p_plane_normal] - p_plane_height)

	const HORIZON_ANGLE := 5.0
	var horizon_distance := 10.0 + (cam_plane_distance * 10.0)

	return cam_angle < deg_to_rad(HORIZON_ANGLE) and dist_sq > horizon_distance


func get_cam_plane_angle(p_cam_look_direction: Vector3, p_plane_normal: int, _p_plane_height: float) -> float:
	var flat_cam_look_direction := p_cam_look_direction
	flat_cam_look_direction[p_plane_normal] = 0.0
	return p_cam_look_direction.angle_to(flat_cam_look_direction)


func calculate_plane_gizmo_pos(p_viewport_camera: Camera3D) -> Vector3:
	var pos := p_viewport_camera.global_position - p_viewport_camera.global_transform.basis.z * 1.0
	pos[get_plane_axis()] = AssetPlacerState.instance.placement_config_state.plane_position
	return pos
