# asset_preview_generator.gd
# © Copyright CookieBadger 2026
@tool
extends Node

const Editor3DViewportUtils = preload("res://addons/assetplacer/utils/editor_3d_viewport_utils.gd")
const PreviewRenderingViewport = preload("res://addons/assetplacer/asset_palette/preview_generation/preview_rendering_viewport.gd")
const Settings = preload("res://addons/assetplacer/settings.gd")
const PropertyUtils = preload("res://addons/assetplacer/utils/property_utils.gd")
const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")
const LoadData = preload("res://addons/assetplacer/asset_palette/preview_generation/load_data.gd")
const TextureCache = preload("res://addons/assetplacer/asset_palette/preview_generation/texture_cache.gd")
const AssetInstantiator = preload("res://addons/assetplacer/asset_palette/asset_instantiator.gd")

const PERSPECTIVE_SETTING := "Preview_Perspective"
const PERSPECTIVE_ANGLE_HORIZONTAL_SETTING := "Preview_Angle_Horizontal"
const PERSPECTIVE_ANGLE_VERTICAL_SETTING := "Preview_Angle_Vertical"
const CACHE_PERSPECTIVE_SEPARATOR := "//<>"
const PREVIEW_VP_COUNT: int = 3

var _pending_load_actions: Array[LoadData] = []
var _texture_cache: TextureCache = TextureCache.new()

var _preview_rendering_viewports: Array[PreviewRenderingViewport] = []
var _dynamic_rendering_viewport: PreviewRenderingViewport


func get_dynamic_preview_vp() -> PreviewRenderingViewport:
	return _dynamic_rendering_viewport


func _enter_tree() -> void:
	_preview_rendering_viewports = []
	for i in range(PREVIEW_VP_COUNT):
		var viewport: PreviewRenderingViewport = load("res://addons/assetplacer/asset_palette/preview_generation/preview_rendering_viewport.tscn").instantiate()
		add_child(viewport)
		if i == 0:
			_dynamic_rendering_viewport = viewport
		else:
			_preview_rendering_viewports.push_back(viewport)

	Settings.register_setting(Settings.DEFAULT_CATEGORY, PERSPECTIVE_SETTING, int(Asset3DData.PreviewPerspective.FRONT), TYPE_INT, PROPERTY_HINT_ENUM, Asset3DData.PERSPECTIVE_ENUM_STRING)
	Settings.register_setting(Settings.DEFAULT_CATEGORY, PERSPECTIVE_ANGLE_HORIZONTAL_SETTING, 20.0, TYPE_FLOAT, PROPERTY_HINT_RANGE, "0,360")
	Settings.register_setting(Settings.DEFAULT_CATEGORY, PERSPECTIVE_ANGLE_VERTICAL_SETTING, 20.0, TYPE_FLOAT, PROPERTY_HINT_RANGE, "0,360")


func _cleanup() -> void:
	for p in _preview_rendering_viewports:
		p.queue_free()
	_dynamic_rendering_viewport.queue_free()


func process() -> void:
	if _pending_load_actions.size() == 0:
		return
	var completed_loads: Array[LoadData] = []
	var vp_maybe_available := true  # optimization to skip a loop

	for load_action: LoadData in _pending_load_actions:
		if vp_maybe_available && load_action.waiting:
			# find first viewport for which no loadVp has been assigned that viewport
			var available_viewport_idx := _preview_rendering_viewports.find_custom(func(vp: PreviewRenderingViewport) -> bool: return vp.is_idle)
			if available_viewport_idx >= 0:
				load_action.waiting = false
				var invalid := load_action.asset.get_ref() == null or load_action.library.get_ref() == null
				if not invalid:
					var asset_node := AssetInstantiator.instantiate_asset(load_action.asset.get_ref(), load_action.library.get_ref())  # instantiate to get the preview working. We don't need the instance itself
					if asset_node == null:
						invalid = true
					else:
						var available_viewport: PreviewRenderingViewport = _preview_rendering_viewports[available_viewport_idx]
						available_viewport.set_preview_node(asset_node, load_action.preview_perspective, load_action.custom_preview)
						load_action.viewport = available_viewport
						const RENDER_SIZE_FACTOR := 2
						available_viewport.size = load_action.size * RENDER_SIZE_FACTOR
						# Set the viewport to always render, such that the image gets updated (will be disabled once finished)
						available_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
						available_viewport.is_idle = false
				if invalid:
					completed_loads.push_back(load_action)
					on_load_finished(load_action)
			else:
				vp_maybe_available = false

		if load_action.viewport != null:
			load_action.loadsteps += 1
			if load_action.viewport.is_preview_ready:
				on_load_finished(load_action)
				completed_loads.push_back(load_action)

	for data: LoadData in completed_loads:
		_pending_load_actions.erase(data)


func cancel_queued_previews() -> void:
	var canceled_loads: Array[LoadData] = []
	for load_action: LoadData in _pending_load_actions:
		if load_action.waiting:
			load_action.action = func(_a: Variant, _b: Variant, _c: Variant, _d: Variant) -> void: pass
			canceled_loads.push_back(load_action)
	for data: LoadData in canceled_loads:
		_pending_load_actions.erase(data)


func generate_for_asset(
	asset: Asset3DData,
	p_size: Vector2i,
	p_on_preview_loaded: Callable,
	p_ignore_cache: bool,
	p_perspective: Asset3DData.PreviewPerspective,
	p_custom_preview: Vector3,
	p_prev_custom_preview: Vector3,
	p_library: WeakRef
) -> bool:
	var texture := _texture_cache.check_cache(get_cache_key(asset.path, p_perspective, p_custom_preview))
	if !p_ignore_cache && texture != null:
		# cache hit
		p_on_preview_loaded.call(p_library, asset.path, texture, p_perspective, p_custom_preview)
		return true

	# no cache hit or ignore
	var resource := ResourceLoader.load(asset.path) if ResourceLoader.exists(asset.path) else null
	if resource is PackedScene or resource is Mesh:
		_pending_load_actions.push_back(LoadData.new(p_on_preview_loaded, weakref(asset), resource, p_size, p_perspective, p_custom_preview, p_prev_custom_preview, p_library))
		return true

	return false  # unsupported resource type


func on_load_finished(p_load_data: LoadData) -> void:
	var texture: Texture2D
	if p_load_data.viewport:
		if Editor3DViewportUtils.is_headless():
			texture = ResourceLoader.load("res://addons/assetplacer/ui/icons/asset_icon.svg")  # placeholder
		else:
			var image := p_load_data.viewport.get_texture().get_image()
			texture = ImageTexture.create_from_image(image)
		p_load_data.viewport.free_preview_node()
		p_load_data.viewport.is_idle = true
		p_load_data.viewport = null

	p_load_data.action.call(p_load_data.library, p_load_data.asset_resource.resource_path, texture, p_load_data.preview_perspective, p_load_data.custom_preview)
	p_load_data.action = func(_a: Variant, _b: Variant, _c: Variant, _d: Variant) -> void: pass

	if texture:
		if p_load_data.preview_perspective == Asset3DData.PreviewPerspective.CUSTOM && p_load_data.prev_custom_preview.x >= 0:
			_texture_cache.remove_from_cache(get_cache_key(p_load_data.asset_resource.resource_path, p_load_data.preview_perspective, p_load_data.prev_custom_preview))
		_texture_cache.add_to_cache(get_cache_key(p_load_data.asset_resource.resource_path, p_load_data.preview_perspective, p_load_data.custom_preview), texture)


static func get_cache_key(p_resource_path: String, p_perspective: Asset3DData.PreviewPerspective, p_custom_preview: Vector3) -> String:
	var custom_preview_str := str(p_custom_preview) if p_perspective == Asset3DData.PreviewPerspective.CUSTOM else ""
	return p_resource_path + CACHE_PERSPECTIVE_SEPARATOR + str(p_perspective) + custom_preview_str


static func get_perspective(p_perspective: Asset3DData.PreviewPerspective) -> Asset3DData.PreviewPerspective:
	# simplified:
	if p_perspective == Asset3DData.PreviewPerspective.DEFAULT:
		return Settings.get_setting(Settings.DEFAULT_CATEGORY, PERSPECTIVE_SETTING)

	return p_perspective
