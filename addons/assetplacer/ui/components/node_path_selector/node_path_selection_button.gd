# node_path_selection_button.gd
# © Copyright CookieBadger 2026
@tool
extends Button

signal node_dropped(node: Node)


func _can_drop_data(_p_at_position: Vector2, p_data: Variant) -> bool:
	if p_data is Dictionary:
		if p_data["type"] == "nodes":
			var paths: Array = p_data["nodes"]
			return paths.size() == 1

	return false


func _drop_data(_p_at_position: Vector2, p_data: Variant) -> void:
	var node_path: String = p_data["nodes"][0]

	var node := get_tree().root.get_node_or_null(node_path)
	if node == null:
		printerr("AssetPlacerPlugin: Node could not be found from path %s, try using selection button instead" % [node_path])
		return
	node_dropped.emit(node)


func set_node(p_node: Node, p_icon: Texture2D) -> void:
	if p_node:
		self.text = p_node.name
		remove_theme_color_override("font_color")
	else:
		self.text = "<null>"
		add_theme_color_override("font_color", Color.RED)
	self.icon = p_icon
