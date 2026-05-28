# physics_surface.gd
# © Copyright CookieBadger 2026
@tool
extends "res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/strategy.gd"

const SpatialUtils = preload("res://addons/assetplacer/utils/spatial_utils.gd")
const EditorRaycast = preload("res://addons/assetplacer/utils/editor_raycast.gd")


# override
func get_placement(p_camera: Camera3D, p_mouse_pos: Vector2, p_placing_nodes: Array[Node3D]) -> RayInfo:
	if p_camera == null:
		return RayInfo.invalid(RayInfo.VALIDITY.NO_INTERSECTION)

	var from := p_camera.project_ray_origin(p_mouse_pos)
	var dir := p_camera.project_ray_normal(p_mouse_pos)
	var raycast := EditorRaycast.new(from, dir, p_camera.projection)

	var world_node := Node3D.new()
	EditorInterface.get_edited_scene_root().add_child(world_node)
	var result := raycast.perform_raycast(world_node.get_world_3d(), p_placing_nodes)
	world_node.queue_free()

	if result.size() <= 0:
		return RayInfo.invalid(RayInfo.VALIDITY.NO_SURFACE, "no_surface")

	var pos: Vector3 = result["position"]
	var normal: Vector3 = result["normal"]

	var ray_info := RayInfo.new(pos, normal)

	return ray_info


# override
func rotate_node(p_node: Node3D, p_start_rotation: Vector3, p_rotation: float) -> void:
	if AssetPlacerState.instance.placement_state.last_valid_ray_info == null:
		return  # should not happen
	p_node.rotation = p_start_rotation
	p_node.global_rotate(AssetPlacerState.instance.placement_state.last_valid_ray_info.normal, p_rotation)
