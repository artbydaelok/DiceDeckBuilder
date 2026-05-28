# contextless_plugin.gd
# © Copyright CookieBadger 2026
extends EditorPlugin

const EditorDrawPanel = preload("res://addons/assetplacer/utils/editor_draw_panel.gd")
const Editor3DViewportUtils = preload("res://addons/assetplacer/utils/editor_3d_viewport_utils.gd")

var _draw_panel: Control
var _init_failed: bool = false

################################
#### Built-ins


func _enter_tree() -> void:
	if !Engine.is_editor_hint():
		return
	_draw_panel = _create_draw_panel()
	EditorInterface.get_base_control().add_child(_draw_panel)

	# _init_vps()

	_initialize()


func _exit_tree() -> void:
	if !Engine.is_editor_hint():
		return
	if _draw_panel and is_instance_valid(_draw_panel):
		_draw_panel.queue_free()
	if !_init_failed:
		_cleanup()


func _input(p_event: InputEvent) -> void:
	if !Engine.is_editor_hint() or _init_failed:
		return
	_forward_input(p_event)
	var viewport := Editor3DViewportUtils.get_focused_3d_viewport()
	if viewport != null and not get_tree().root.is_input_handled():
		# offset positional events, such that 0,0 is at the beginning of the viewport
		var justified_event := p_event
		#var property_list := event.get_property_list()
		#if property_list.any(func (d) -> void: d["name"] == "position") -> void:
		if "position" in p_event:
			justified_event = p_event.duplicate()
			var offset_position: Vector2 = justified_event.position - viewport.get_screen_transform().get_origin()
			justified_event.position = offset_position / viewport.get_screen_transform().get_scale()

		# If it is a mouse event, only forward if the mouse is over the viewport (not over some buttons or other overlayed ui)
		if not p_event is InputEventMouse or Editor3DViewportUtils.is_mouse_over_valid_focused_3d_viewport():
			_forward_3d_viewport_input(viewport, justified_event)


func _unhandled_input(p_event: InputEvent) -> void:
	if !Engine.is_editor_hint() || _init_failed:
		return
	var vp := Editor3DViewportUtils.get_focused_3d_viewport()
	if vp != null:
		_forward_3d_viewport_unhandled_input(vp, p_event)


func _process(p_delta: float) -> void:
	if !Engine.is_editor_hint() || _init_failed:
		return
	_process_update(p_delta)
	_draw_panel.queue_redraw()


#####################################


func _initialize() -> void:
	pass


func _cleanup() -> void:
	pass


#gdlint:disable = unused-argument
@warning_ignore("unused_parameter")  # overrideable #
func _forward_input(p_event: InputEvent) -> void:
	pass


@warning_ignore("unused_parameter")  # overrideable
func _forward_3d_viewport_input(p_viewport: SubViewport, p_event: InputEvent) -> void:
	return


@warning_ignore("unused_parameter")  # overrideable
func _forward_3d_viewport_unhandled_input(p_viewport: SubViewport, p_event: InputEvent) -> void:
	return


@warning_ignore("unused_parameter")  # overrideable
func _process_update(p_delta: float) -> void:
	pass


#gdlint:enable = unused-argument


func _create_draw_panel() -> EditorDrawPanel:
	return EditorDrawPanel.new()
