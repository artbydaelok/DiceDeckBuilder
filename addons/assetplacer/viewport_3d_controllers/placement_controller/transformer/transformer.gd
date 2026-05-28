# transformer.gd
# © Copyright CookieBadger 2026
@tool

const RayInfo = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/ray_info.gd")
const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")
const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const SpatialUtils = preload("res://addons/assetplacer/utils/spatial_utils.gd")
const SquareSnapping = preload("res://addons/assetplacer/viewport_3d_controllers/snapping_strategy/square.gd")

var _transform: Transform3D = Transform3D.IDENTITY

var _use_randomizer: bool = false
var _use_surface_align: bool = false
var _use_snapping: bool = false


func _init(asset_3d: Asset3DData, use_snapping: bool = false, use_surface_align: bool = false, use_randomizer: bool = false) -> void:
	self._transform = asset_3d.current_transform
	self._use_randomizer = use_randomizer
	self._use_surface_align = use_surface_align
	self._use_snapping = use_snapping


func get_transform(ray_info: RayInfo) -> Transform3D:
	# # apply rotation that the strategy specifies
	var processed_transform := _transform

	if not ray_info.is_valid():
		return processed_transform

	if _use_surface_align:
		var axis := SpatialUtils.get_align_axis(Transform3D.IDENTITY, AssetPlacerState.instance.placement_config_state.surface_align_axis)
		var q := SpatialUtils.get_vector_rotation(axis, ray_info.normal)
		processed_transform.basis = Basis(q).scaled(processed_transform.basis.get_scale())

	if _use_snapping:
		processed_transform.origin = SquareSnapping.snap_pos_with_offset(
			ray_info.pos, ray_info.normal, AssetPlacerState.instance.snapping_state.current_step, AssetPlacerState.instance.snapping_state.offset
		)
	else:
		processed_transform.origin = ray_info.pos

	if _use_randomizer:
		pass  # TODO[Randomizer]

	return processed_transform
