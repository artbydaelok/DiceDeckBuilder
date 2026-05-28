# asset_persistent_data.gd
# © Copyright CookieBadger 2026
@tool
extends Resource

const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")
const AssetPersistentData = preload("res://addons/assetplacer/asset_palette/asset_persistent_data.gd")

@export var version := 1
@export var path: String
@export var is_mesh: bool
@export var preview_perspective: Asset3DData.PreviewPerspective
@export var custom_preview: Vector3
@export var transform: Transform3D = Transform3D.IDENTITY
@export var transform_valid: bool = false


func _init(
	p_path: String = "",
	p_is_mesh: bool = false,
	p_preview_perspective: Asset3DData.PreviewPerspective = Asset3DData.PreviewPerspective.DEFAULT,
	p_custom_preview: Vector3 = Vector3.ZERO,
	p_transform: Transform3D = Transform3D.IDENTITY,
	p_transform_valid: bool = false
) -> void:
	self.path = p_path
	self.is_mesh = p_is_mesh
	self.preview_perspective = p_preview_perspective
	self.custom_preview = p_custom_preview
	self.transform = p_transform
	self.transform_valid = p_transform_valid


static func get_asset_3d_data(p_data: AssetPersistentData) -> Asset3DData:
	return Asset3DData.new(p_data.path, p_data.preview_perspective, p_data.custom_preview, p_data.is_mesh, p_data.transform, p_data.transform_valid)
