# asset_library.gd
# © Copyright CookieBadger 2026
@tool
extends Resource

const AssetLibrary = preload("res://addons/assetplacer/asset_palette/asset_library.gd")
const AssetLibraryData = preload("res://addons/assetplacer/asset_palette/asset_library_data.gd")
const AssetPersistentData = preload("res://addons/assetplacer/asset_palette/asset_persistent_data.gd")
const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")

@export var version := 1
@export var asset_data: Array[AssetPersistentData] = []
@export var preview_perspective: Asset3DData.PreviewPerspective


static func build_asset_library(p_library_data: AssetLibraryData) -> AssetLibrary:
	var data := p_library_data.asset_data.map(
		func(d: Asset3DData) -> AssetPersistentData: return AssetPersistentData.new(d.path, d.is_mesh, d.preview_perspective, d.custom_preview, d.current_transform, d.current_transform_valid)
	)
	var library := AssetLibrary.new()
	library.asset_data.assign(data)
	library.preview_perspective = p_library_data.preview_perspective
	return library


func unpack_into(p_library_data: AssetLibraryData) -> void:
	# load library settings
	var asset_3d_data: Array = asset_data.map(func(a: AssetPersistentData) -> Asset3DData: return AssetPersistentData.get_asset_3d_data(a))
	p_library_data.asset_data.assign(asset_3d_data)

	p_library_data.preview_perspective = preview_perspective
