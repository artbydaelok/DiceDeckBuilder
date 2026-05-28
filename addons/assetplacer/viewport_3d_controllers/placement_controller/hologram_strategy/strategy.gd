# strategy.gd
# © Copyright CookieBadger 2026
@tool

const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")
const RayInfo = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/ray_info.gd")

# gdlint:disable=unused-argument
@warning_ignore("unused_parameter")
func create_hologram(p_asset: Asset3DData, p_ray_info: RayInfo, p_transform: Transform3D) -> Node3D:
	return null


@warning_ignore("unused_parameter")
func update_hologram(p_hologram: Node3D, p_ray_info: RayInfo, p_transform: Transform3D) -> void:
	pass
# gdlint:enable=unused-argument
