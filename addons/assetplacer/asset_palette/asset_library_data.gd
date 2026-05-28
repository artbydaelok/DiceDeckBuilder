# asset_library_data.gd
# © Copyright CookieBadger 2026
@tool
extends Object

const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")

var asset_data: Array[Asset3DData] = []
var preview_perspective: Asset3DData.PreviewPerspective
var dirty: bool = true
var save_path: String


func get_asset_paths() -> Array[String]:
	var paths: Array[String] = []
	paths.assign(asset_data.map(func(a: Asset3DData) -> String: return a.path))
	return paths


func has_asset(p_path: String) -> bool:
	return asset_data.any(func(a: Asset3DData) -> bool: return a.path == p_path)


func remove_asset(p_path: String) -> void:
	var rm_list: Array[Asset3DData] = []
	for data in asset_data:
		if data.path == p_path:
			rm_list.append(data)

	for data in rm_list:
		asset_data.erase(data)


func get_asset(p_path: String) -> Asset3DData:
	var filter := asset_data.filter(func(a: Asset3DData) -> bool: return a.path == p_path)
	return filter[0] if filter.size() > 0 else null
