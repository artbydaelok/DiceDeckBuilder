# strategy.gd
# © Copyright CookieBadger 2026
@tool

const Node3DList = preload("res://addons/assetplacer/data_formats/node_3d_list.gd")
const RayInfo = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/ray_info.gd")
const RayStrategy = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/strategy.gd")
const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")
const Transformer = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/transformer/transformer.gd")
const Tips = preload("res://addons/assetplacer/tooltip_panel.gd")
const Lang = preload("res://addons/assetplacer/lang.gd")

# gdlint:disable=unused-argument
## returns success, if false is returned, the placement is not valid, and dragging will not have any effect
@warning_ignore("unused_parameter")  # overrideable
func begin_drag(
	p_viewport: SubViewport,
	p_asset: Asset3DData,
	p_prototype: Node3D,
	p_spawn_parent: Node,
	p_ray_strategy: RayStrategy,
	p_first_ray_info: RayInfo,
	p_transformer: Transformer,
	p_first_transform: Transform3D,
	p_tip_key: String
) -> bool:
	return true


func end_drag() -> Node3DList:
	return Node3DList.new([])


@warning_ignore("unused_parameter")  # overrideable
func drag(p_viewport: SubViewport, p_mouse_pos: Vector2, p_tip_key: String) -> void:
	pass
# gdlint:enable=unused-argument
