# load_data.gd
# © Copyright CookieBadger 2026
@tool

const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")
const PreviewRenderingViewport = preload("res://addons/assetplacer/asset_palette/preview_generation/preview_rendering_viewport.gd")

var viewport: PreviewRenderingViewport
var action: Callable
var loadsteps: int
var asset_resource: Resource
var waiting: bool
var size: Vector2i
var preview_perspective: Asset3DData.PreviewPerspective
var custom_preview: Vector3
var prev_custom_preview: Vector3
var library: WeakRef
var asset: WeakRef


func _init(
	p_action: Callable,
	p_asset: WeakRef,
	p_asset_resource: Resource,
	p_size: Vector2i,
	p_preview_perspective: Asset3DData.PreviewPerspective,
	p_custom_preview: Vector3,
	p_prev_custom_preview: Vector3,
	p_library: WeakRef
) -> void:
	self.action = p_action
	self.asset = p_asset
	self.asset_resource = p_asset_resource
	self.library = p_library
	self.size = p_size
	self.preview_perspective = p_preview_perspective
	self.custom_preview = p_custom_preview
	self.prev_custom_preview = p_prev_custom_preview
	self.loadsteps = 0
	self.waiting = true
