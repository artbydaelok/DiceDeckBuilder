# asset_instantiator.gd
# © Copyright CookieBadger 2026
@tool

const AssetPlacerState = preload("res://addons/assetplacer/assetplacer_state.gd")
const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")
const AssetLibraryData = preload("res://addons/assetplacer/asset_palette/asset_library_data.gd")


static func instantiate_asset(p_asset: Asset3DData, p_library: AssetLibraryData) -> Node3D:
	if p_asset == null:
		printerr("AssetPlacerPlugin: Cannot instantiate p_asset: Asset is null")
		return null
	if not ResourceLoader.exists(p_asset.path):
		printerr("AssetPlacerPlugin: Cannot find resource at %s: File might have been deleted or moved" % p_asset.path)
		AssetPlacerState.instance.palette_state.set_asset_broken(p_asset, true)
		return null

	var asset_resource := load(p_asset.path)
	var asset_instance: Node3D = null

	# update button in case its a different type
	var update_button := false
	if p_asset.is_mesh != asset_resource is Mesh:
		update_button = true
		p_asset.is_mesh = asset_resource is Mesh

	if update_button && p_library != null && p_library == AssetPlacerState.instance.palette_state.current_library_data:
		AssetPlacerState.instance.palette_state.asset_updated.emit(p_asset, false)
		AssetPlacerState.instance.palette_state.mark_library_dirty(p_library, true)

	if asset_resource is PackedScene:
		var instance: Node = asset_resource.instantiate()
		if instance is Node3D:
			asset_instance = instance
		elif instance is Object:
			instance.free()
	elif asset_resource is Mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = asset_resource
		asset_instance = mesh_instance

	if asset_instance == null:
		printerr("AssetPlacerPlugin: Cannot instantiate asset at %s: Resource type is not supported (3D scenes and meshes are supported)." % [p_asset.path])
		AssetPlacerState.instance.palette_state.set_asset_broken(p_asset, true)
	else:
		p_asset.default_transform = asset_instance.transform  # as is upon instantiation, used for resetting
		if p_asset.is_broken:
			AssetPlacerState.instance.palette_state.broken_asset_instantiated.emit(p_asset)
			AssetPlacerState.instance.palette_state.set_asset_broken(p_asset, false)

	return asset_instance
