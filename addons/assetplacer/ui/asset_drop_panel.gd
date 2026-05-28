# asset_drop_panel.gd
# © Copyright CookieBadger 2026
@tool
extends Node

signal assets_dropped(asset_paths: PackedStringArray)


static func can_drop_data(p_data: Variant) -> bool:
	if p_data is Dictionary:
		if p_data["type"] == "files":
			var paths: Array = p_data["files"]
			return !paths.is_empty()
	return false


func _can_drop_data(_p_at_position: Vector2, p_data: Variant) -> bool:
	return can_drop_data(p_data)


func _drop_data(_p_at_position: Vector2, p_data: Variant) -> void:
	assets_dropped.emit(p_data["files"])
