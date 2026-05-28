# editor_3d_viewport_utils.gd
# © Copyright CookieBadger 2026
@tool

const VP_WARP_ZONE := 0.01


static func print_index_path(p_from_node: Node, p_to_node: Node) -> void:
	var path := p_from_node.get_path_to(p_to_node)
	var idxpath := ""
	var node := p_from_node
	for s in str(path).split("/"):
		node = node.get_node(s)
		idxpath += str(node.get_index()) + "/"
	print(idxpath)


static func get_3d_viewports() -> Array[SubViewport]:
	var viewports: Array[SubViewport] = []
	if Engine.get_version_info().minor >= 7:
		for i in range(4):
			viewports.append(EditorInterface.get_editor_viewport_3d(i))
	else:
		# for 2D: MainScreen -> @CanvasItemEditor@9462:<CanvasItemEditor#702965385689> -> @VSplitContainer@9281:<VSplitContainer#703099603425>
		#		 	-> @HSplitContainer@9283:<HSplitContainer#703166712293> -> @HSplitContainer@9285:<HSplitContainer#703233821161> -> @Control@9286:<Control#703300930029>
		# 			-> @SubViewportContainer@9287:<SubViewportContainer#703334484463>
		# for 3D: MainScreen -> Node3DEditor -> MarginContainer -> HSplitContainer -> HSplitContainer -> VSplitContainer -> Node3DEditorViewportContainer
		var main_screen := EditorInterface.get_editor_main_screen()
		var hsplit_container_1 := main_screen.get_child(1).get_child(1)
		var hsplit_container_2 := hsplit_container_1.get_child(hsplit_container_1.get_child_count() - 1)  # last child
		var viewport_container := hsplit_container_2.get_child(0).get_child(0)
		var node_3d_editor_viewports := viewport_container.get_children()
		for v in node_3d_editor_viewports:
			viewports.append(v.get_child(0).get_child(0))

	return viewports


static func get_focused_3d_viewport() -> SubViewport:
	var viewports := get_3d_viewports()
	for vp in viewports:
		if is_editor_viewport_focused(vp):
			return vp
	return null


static func is_editor_viewport_focused(p_viewport: Viewport) -> bool:
	var editor_vp: Control = p_viewport.get_parent().get_parent()
	var vp_control: Control = editor_vp.get_child(1)
	return editor_vp.visible and (vp_control != null and vp_control.has_focus())


static func is_headless() -> bool:
	return DisplayServer.get_name().to_lower() == "headless"


static func get_3d_viewport_under_mouse() -> SubViewport:
	# MainScreen -> Node3DEditor
	if is_headless():
		return get_focused_3d_viewport()
	var main_screen_3d_visible: bool = EditorInterface.get_editor_main_screen().get_child(1).visible
	if not main_screen_3d_visible:
		return null

	var viewports := get_3d_viewports()
	for vp in viewports:
		if vp.get_parent().get_parent().visible == false:
			continue
		var vp_pos := vp.get_screen_transform().origin
		var vp_size := vp.get_visible_rect().size * vp.get_screen_transform().get_scale()
		var vp_rect := Rect2(vp_pos, vp_size)
		if vp_rect.has_point(EditorInterface.get_base_control().get_viewport().get_mouse_position()):
			return vp
	return null


static func is_mouse_over_valid_focused_3d_viewport() -> bool:
	var focused_vp := get_focused_3d_viewport()
	var mouse_vp := get_3d_viewport_under_mouse()
	if mouse_vp != null && focused_vp != null:
		return mouse_vp == focused_vp && not is_editor_viewport_previewing_camera(mouse_vp)
	return false


static func focus_editor_viewport(p_viewport: Viewport) -> void:
	var editor_vp: Control = p_viewport.get_parent().get_parent()
	var vp_control: Control = editor_vp.get_child(1)
	if editor_vp.visible and vp_control != null:
		vp_control.grab_focus()


static func get_editor_viewport_rect(p_viewport: Viewport) -> Rect2:
	# input control has the actual size of the viewport
	var editor_vp: Control = p_viewport.get_parent().get_parent()
	return editor_vp.get_child(1).get_global_rect()


static func is_editor_viewport_previewing_camera(p_viewport: Viewport) -> bool:
	var viewport_container := p_viewport.get_parent().get_parent()  # Node3DEditorViewportContainer
	var preview_checkbox: Button
	if Engine.get_version_info().minor >= 7:
		preview_checkbox = viewport_container.get_child(1).get_child(0).get_child(2)
	else:
		preview_checkbox = viewport_container.get_child(1).get_child(0).get_child(1)  # Node3DEditorViewportContainer -> Control -> VBoxContainer -> Checkbox (preview)
	return preview_checkbox.button_pressed


static func get_viewport_unit_mouse_position(p_viewport: Viewport) -> Vector2:
	return p_viewport.get_mouse_position() / p_viewport.get_visible_rect().size


static func warp_mouse_to_center_if_outside(p_viewport: SubViewport) -> void:
	var vp_size := p_viewport.get_visible_rect().size
	var vp_rect := Rect2(vp_size * VP_WARP_ZONE, vp_size * (1 - 2 * VP_WARP_ZONE))
	if not vp_rect.has_point(p_viewport.get_mouse_position()):
		p_viewport.warp_mouse(0.5 * vp_size)


static func warp_mouse_inside_viewport(p_viewport: SubViewport) -> Vector2:
	var warp_vec := Vector2()
	var vp_size := p_viewport.get_visible_rect().size
	var unit_rect := Rect2(Vector2.ZERO, Vector2.ONE)
	var warp_rect := Rect2(vp_size * VP_WARP_ZONE, vp_size * (1 - 2 * VP_WARP_ZONE))
	var vp_unit_mouse_pos := get_viewport_unit_mouse_position(p_viewport)
	var is_mouse_over_viewport := unit_rect.has_point(vp_unit_mouse_pos)
	if not is_mouse_over_viewport:
		var clamp_pos := vp_unit_mouse_pos.clamp(Vector2.ZERO, Vector2.ONE)
		var warp_pos := warp_rect.position + clamp_pos * warp_rect.size
		var warp_distance := 1 - VP_WARP_ZONE

		if clamp_pos.x >= 1:
			warp_pos.x = warp_rect.position.x
			warp_vec.x = -warp_distance
		elif clamp_pos.x <= 0:
			warp_pos.x = warp_rect.position.x + warp_rect.size.x
			warp_vec.x = warp_distance
		if clamp_pos.y >= 1:
			warp_pos.y = warp_rect.position.y
			warp_vec.y = -warp_distance
		elif clamp_pos.y <= 0:
			warp_pos.y = warp_rect.position.y + warp_rect.size.y
			warp_vec.y = warp_distance

		p_viewport.warp_mouse(warp_pos)
	return warp_vec
