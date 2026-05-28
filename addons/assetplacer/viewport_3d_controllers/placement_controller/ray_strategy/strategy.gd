# strategy.gd
# © Copyright CookieBadger 2026
@tool

const RayInfo = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/ray_info.gd")
const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const Lang = preload("res://addons/assetplacer/lang.gd")


func get_grid_placement() -> RayInfo:
	if AssetPlacerState.instance.placement_state.last_valid_ray_info != null:
		return AssetPlacerState.instance.placement_state.last_valid_ray_info
	return RayInfo.invalid()


func get_placement_plane(p_last_ray_info: RayInfo) -> RayInfo:
	if p_last_ray_info != null and p_last_ray_info.is_valid():
		return p_last_ray_info
	return RayInfo.invalid()


## placing nodes: array of nodes that are being placed, used to ignore them in the raycasting (avoid placing over itself)
@warning_ignore("unused_parameter")  # overrideable
# gdlint:ignore = unused-argument
func get_placement(p_camera: Camera3D, p_mouse_pos: Vector2, p_placing_nodes: Array[Node3D]) -> RayInfo:
	return RayInfo.new()
