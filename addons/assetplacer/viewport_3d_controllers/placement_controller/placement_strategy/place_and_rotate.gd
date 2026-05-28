# place_and_rotate.gd
# © Copyright CookieBadger 2026
@tool
extends "res://addons/assetplacer/viewport_3d_controllers/placement_controller/placement_strategy/strategy.gd"

const AssetPaletteController = preload("res://addons/assetplacer/viewport_3d_controllers/asset_palette_controller.gd")
const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const Editor3DViewportUtils = preload("res://addons/assetplacer/utils/editor_3d_viewport_utils.gd")
const InputManager = preload("res://addons/assetplacer/input_manager.gd")

const FULL_ROTATION_MOUSE_VIEWPORT_DISTANCE = 0.5

var palette_state: AssetPlacerState.PaletteState:
	get:
		return AssetPlacerState.instance.palette_state

var _rotating_hologram_mouse_start: float = 0.0
var _placing_node: Node3D
var _ray_info: RayInfo
var _start_rotation: Vector3


# override
func begin_drag(
	p_viewport: SubViewport,
	_p_asset: Asset3DData,
	p_prototype: Node3D,
	p_spawn_parent: Node,
	_p_ray_strategy: RayStrategy,
	p_first_ray_info: RayInfo,
	_p_transformer: Transformer,
	p_first_transform: Transform3D,
	_p_tip_key: String
) -> bool:
	_rotating_hologram_mouse_start = InputManager.instance.viewport_mouse_position.x / p_viewport.get_visible_rect().size.x
	_placing_node = p_prototype.duplicate()
	p_spawn_parent.add_child(_placing_node)
	AssetPlacerState.instance.placement_state.notify_placement(_placing_node)
	_placing_node.global_transform = p_first_transform
	_ray_info = p_first_ray_info
	_start_rotation = _placing_node.rotation
	return true


# override
func end_drag() -> Node3DList:
	# undo system
	return Node3DList.new([_placing_node])


# override
func drag(p_viewport: SubViewport, _p_mouse_pos: Vector2, p_tip_key: String) -> void:
	# warp mouse
	var warp := Editor3DViewportUtils.warp_mouse_inside_viewport(p_viewport)
	_rotating_hologram_mouse_start += warp.x

	# rotate asset
	const ROTATION_DEAD_ZONE = 0.01
	var dist: float = _get_mouse_dist_with_deadzone(p_viewport, _rotating_hologram_mouse_start, ROTATION_DEAD_ZONE)
	var rotation := fmod((dist) * TAU / FULL_ROTATION_MOUSE_VIEWPORT_DISTANCE, TAU)
	if dist == 0.0:
		Tips.set_tt(p_tip_key.path_join("rotate/deg"), " ", Tips.TYPE.VALUE, 1, false, true)  # empty line
		Tips.set_tt(p_tip_key.path_join("rotate/hint"), Lang.ttr("rotate_place"), Tips.TYPE.HINT, 0, false, true)
	else:
		Tips.set_tt(p_tip_key.path_join("rotate/deg"), "%.3f°" % [rad_to_deg(rotation)], Tips.TYPE.VALUE, 1, false, true)
		Tips.set_tt(p_tip_key.path_join("rotate/hint"), Lang.ttr("rotate_place"), Tips.TYPE.HINT, 0, false, true)

	_placing_node.rotation = _start_rotation
	_placing_node.global_rotate(_ray_info.normal, rotation)


func _get_mouse_dist_with_deadzone(p_viewport: SubViewport, p_start_pos: float, p_mouse_dead_zone: float) -> float:
	var mouse_pos := InputManager.instance.viewport_mouse_position.x / p_viewport.get_visible_rect().size.x
	var dist := mouse_pos - p_start_pos
	dist -= sign(dist) * min(p_mouse_dead_zone, abs(dist))
	return dist
