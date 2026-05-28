# plane_controller.gd
# © Copyright CookieBadger 2026
@tool
extends "res://addons/assetplacer/viewport_3d_controllers/viewport_3d_controller.gd"

const LineGizmo = preload("res://addons/assetplacer/gizmos/line_gizmo.gd")
const PlaneGizmo = preload("res://addons/assetplacer/gizmos/plane_gizmo.gd")
const Shortcuts = preload("res://addons/assetplacer/shortcuts.gd")
const PlaneStrategy = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/plane.gd")
const SpatialUtils = preload("res://addons/assetplacer/utils/spatial_utils.gd")

const EPSILON := 1e-4

var _plane_move_mouse_start := Vector2.ZERO
var _last_mouse_diff_vec := Vector2.INF
var _plane_pos_before_move := 0.0
var _configuring_plane_viewport: SubViewport

var _plane_moving_gizmo: LineGizmo = null
var _plane_gizmo: PlaneGizmo = null
var _plane_transformed := false

var _plane_strategy := PlaneStrategy.new()

var _buffer := ""
var _buffer_sign := 1.0

var _configuring_plane_active: bool:
	get:
		return AssetPlacerState.instance.placement_state.configuring_plane_active
	set(value):
		AssetPlacerState.instance.snapping_state.toggle_users.update_usage("plane_controller", value)
		AssetPlacerState.instance.placement_state.configuring_plane_active = value


func initialize() -> void:
	AssetPlacerState.instance.placement_config_state.plane_positions_changed.connect(func(_positions: Array[float]) -> void: _on_plane_changed())
	AssetPlacerState.instance.placement_config_state.plane_changed.connect(func(_plane: int) -> void: _on_plane_changed())

	AssetPlacerState.instance.snapping_state.step_changed.connect(func(_v: float) -> void: _update_gizmo_pattern())
	AssetPlacerState.instance.snapping_state.offset_changed.connect(func(_v: Vector2) -> void: _update_gizmo_pattern())

	Shortcuts.instance.add_simple_keys_3d_gui_shortcut(Shortcuts.PLACEMENT_PLANE_POSITION, [KEY_G])
	Shortcuts.instance.add_simple_keys_3d_gui_shortcut(Shortcuts.SELECT_XY_PLANE, [KEY_C])
	Shortcuts.instance.add_simple_keys_3d_gui_shortcut(Shortcuts.SELECT_XZ_PLANE, [KEY_X])
	Shortcuts.instance.add_simple_keys_3d_gui_shortcut(Shortcuts.SELECT_YZ_PLANE, [KEY_Z])
	initialize_gizmos_if_invalid()


func cleanup() -> void:
	free_plane_gizmo()
	free_plane_moving_gizmo()


func forward_3d_viewport_input(p_viewport: SubViewport, p_event: InputEvent, p_action: InputManager.ActionType) -> void:
	if not AssetPlacerState.instance.placement_config_state.ray_mode == AssetPlacerState.PlacementConfigState.RayMode.PLANE:
		return
	if _configuring_plane_active and not EditorInterface.get_edited_scene_root():  # if no scene root, can't use gizmos
		end_configuring_plane()
		return
	if AssetPlacerState.instance.placement_state.control_state == AssetPlacerState.PlacementState.ControlState.PLACING_ASSET:  # while placing asset, plane can't be configured
		if _configuring_plane_active:
			end_configuring_plane()
		return

	if Shortcuts.instance.is_shortcut(Shortcuts.SELECT_XY_PLANE, p_event):
		AssetPlacerState.instance.placement_config_state.plane = AssetPlacerState.PlacementConfigState.PlacementPlane.XY
		set_placement_plane_transform(p_viewport.get_camera_3d())
		accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.SELECT_XZ_PLANE, p_event):
		AssetPlacerState.instance.placement_config_state.plane = AssetPlacerState.PlacementConfigState.PlacementPlane.XZ
		set_placement_plane_transform(p_viewport.get_camera_3d())
		accept_input()
	elif Shortcuts.instance.is_shortcut(Shortcuts.SELECT_YZ_PLANE, p_event):
		AssetPlacerState.instance.placement_config_state.plane = AssetPlacerState.PlacementConfigState.PlacementPlane.YZ
		set_placement_plane_transform(p_viewport.get_camera_3d())
		accept_input()
	if Shortcuts.instance.is_shortcut(Shortcuts.PLACEMENT_PLANE_POSITION, p_event):
		if _configuring_plane_active:
			end_configuring_plane()
		else:
			start_configuring_plane(p_viewport)
		accept_input()

	elif p_action == InputManager.ActionType.CANCEL and _configuring_plane_active:
		cancel_configuring_plane()
		accept_input()
	elif (p_action == InputManager.ActionType.CONFIRM or p_action == InputManager.ActionType.PLACEMENT) and _configuring_plane_active:
		end_configuring_plane()
		accept_input()

	if _configuring_plane_active:
		if p_event is InputEventKey and p_event.pressed and not p_event.echo:
			_try_type_number(p_event)
			accept_input()


func _try_type_number(p_event: InputEventKey) -> bool:
	var key := p_event.keycode

	# Handle Backspace
	if key == KEY_BACKSPACE:
		_buffer = _buffer.substr(0, max(_buffer.length() - 1, 0))

	elif key == KEY_MINUS or key == KEY_KP_SUBTRACT:
		_buffer_sign *= -1.0

	elif p_event.unicode > 0:
		var c := char(p_event.unicode)
		const ALLOWED_CHARS := "0123456789,.-+*/^()"
		if ALLOWED_CHARS.find(c) == -1:
			return false  # not an allowed character, ignore the input

		if c == ",":
			c = "."  # replace comma with dot for decimal separator
		_buffer += c

	Tips.set_tt("plane/pos", str(_buffer), Tips.TYPE.VALUE)
	var result := _evaluate_expression(_buffer)
	var value := 0.0
	if result[0]:
		value = result[1] * _buffer_sign
	else:
		value = _buffer.to_float() * _buffer_sign

	AssetPlacerState.instance.placement_config_state.plane_position = value
	return true


func _update_gizmo_pattern() -> void:
	if _plane_gizmo:
		_plane_gizmo.set_checker_pattern(AssetPlacerState.instance.snapping_state.step, AssetPlacerState.instance.snapping_state.offset)


func _on_plane_changed() -> void:
	if _configuring_plane_active == true:  # gizmo visible regardless
		return
	var viewport: SubViewport = _configuring_plane_viewport
	if viewport == null:
		viewport = Editor3DViewportUtils.get_focused_3d_viewport()
	if viewport == null:
		viewport = Editor3DViewportUtils.get_3d_viewports()[0]
	set_placement_plane_transform(viewport.get_camera_3d())
	if _plane_gizmo:
		_plane_gizmo.show_temporarily()


func _reset_expression_buffer() -> void:
	_buffer = ""
	_buffer_sign = 1.0


func start_configuring_plane(p_viewport: SubViewport) -> void:
	_plane_pos_before_move = AssetPlacerState.instance.placement_config_state.plane_position
	_configuring_plane_viewport = p_viewport
	_configuring_plane_active = true
	_reset_expression_buffer()

	Editor3DViewportUtils.warp_mouse_to_center_if_outside(p_viewport)
	_plane_move_mouse_start = Editor3DViewportUtils.get_viewport_unit_mouse_position(p_viewport)


func cancel_configuring_plane() -> void:
	end_configuring_plane()
	AssetPlacerState.instance.placement_config_state.plane_position = _plane_pos_before_move


func end_configuring_plane() -> void:
	Tips.clear_tt("plane")
	if _plane_gizmo and _plane_moving_gizmo:
		_plane_gizmo.show_temporarily()
		_plane_moving_gizmo.visible = false
	_configuring_plane_active = false
	_last_mouse_diff_vec = Vector2.INF


func free_plane_gizmo() -> void:
	if _plane_gizmo != null:
		_plane_gizmo.queue_free()
		_plane_gizmo = null


func free_plane_moving_gizmo() -> void:
	if _plane_moving_gizmo != null:
		_plane_moving_gizmo.queue_free()
		_plane_moving_gizmo = null


func process() -> void:
	if _configuring_plane_active:
		process_configuring_plane()
	else:
		_plane_transformed = false


func initialize_gizmos_if_invalid() -> void:
	var scene_root := EditorInterface.get_edited_scene_root()
	if not scene_root:
		return
	if _plane_moving_gizmo != null and not _plane_moving_gizmo.is_inside_tree():
		free_plane_moving_gizmo()

	if _plane_gizmo != null and not _plane_gizmo.is_inside_tree():
		free_plane_gizmo()

	if _plane_moving_gizmo == null:
		_plane_moving_gizmo = LineGizmo.new()
		_plane_moving_gizmo.create_mesh()
		scene_root.add_child(_plane_moving_gizmo)
		_plane_moving_gizmo.tree_exited.connect(free_plane_moving_gizmo)
		_plane_moving_gizmo.visible = false

	if _plane_gizmo == null:
		_plane_gizmo = PlaneGizmo.new()
		scene_root.add_child(_plane_gizmo)
		_plane_gizmo.tree_exited.connect(free_plane_gizmo)
		_plane_gizmo.set_visibility(false)
		_update_gizmo_pattern()


func process_configuring_plane() -> void:
	var scene_root := EditorInterface.get_edited_scene_root()
	var viewport := _configuring_plane_viewport

	if not scene_root or not viewport or not viewport.is_inside_tree() or not viewport.get_parent().get_parent().visible:
		cancel_configuring_plane()
		return

	if not Editor3DViewportUtils.is_editor_viewport_focused(_configuring_plane_viewport):
		Editor3DViewportUtils.focus_editor_viewport(_configuring_plane_viewport)

	var viewport_camera := viewport.get_camera_3d()

	initialize_gizmos_if_invalid()

	if not _plane_transformed:
		set_placement_plane_transform(viewport_camera)
		_plane_transformed = true

	_plane_moving_gizmo.visible = true

	var g := _plane_gizmo.global_position
	g[PlaneStrategy.get_plane_axis()] = AssetPlacerState.instance.placement_config_state.plane_position
	_plane_gizmo.global_position = g

	_plane_gizmo.set_visibility(true)

	var camera_pos := viewport_camera.global_position
	var camera_forward := -viewport_camera.global_transform.basis.z
	var cam_rot := viewport_camera.transform.basis.get_euler()
	var cam_to_plane_angle := 0.0

	match PlaneStrategy.get_plane_axis():
		Vector3.AXIS_Y:
			_plane_moving_gizmo.rotation = Vector3.ZERO
			cam_to_plane_angle = cam_rot.x
		Vector3.AXIS_X:
			_plane_moving_gizmo.rotation = Vector3(deg_to_rad(90), 0, deg_to_rad(90))
			cam_to_plane_angle = cam_rot.y
		Vector3.AXIS_Z:
			_plane_moving_gizmo.rotation = Vector3(deg_to_rad(90), 0, 0)
			cam_to_plane_angle = cam_rot.y
		_:
			push_error("INVALID_PLANE_AXIS")

	var scale_due_to_angle := pow(clamp(abs(cam_to_plane_angle) / (PI / 2), 0.0, 1.0), 2) * 10.0
	_plane_moving_gizmo.scale = Vector3.ONE * 4.0 * scale_due_to_angle
	_plane_moving_gizmo.global_position = camera_pos + camera_forward * (1.0 + viewport_camera.near * 2.0)

	var warp := Editor3DViewportUtils.warp_mouse_inside_viewport(viewport)
	_plane_move_mouse_start += warp
	var vp_unit_mouse_pos := Editor3DViewportUtils.get_viewport_unit_mouse_position(viewport)
	var mouse_diff_vec := vp_unit_mouse_pos - _plane_move_mouse_start
	if mouse_diff_vec.is_equal_approx(_last_mouse_diff_vec):
		return
	_reset_expression_buffer()
	_last_mouse_diff_vec = mouse_diff_vec
	var cam_to_plane_distance := viewport_camera.global_position[PlaneStrategy.get_plane_axis()] - _plane_pos_before_move

	var mouse_diff := 0.0
	match PlaneStrategy.get_plane_axis():
		Vector3.AXIS_Y:
			mouse_diff = -mouse_diff_vec.y
		Vector3.AXIS_X:
			mouse_diff = mouse_diff_vec.x * cos(viewport_camera.rotation.y) + mouse_diff_vec.y * sin(viewport_camera.rotation.y) * sign(-viewport_camera.rotation.x)
		Vector3.AXIS_Z:
			mouse_diff = mouse_diff_vec.x * -sin(viewport_camera.rotation.y) + mouse_diff_vec.y * cos(viewport_camera.rotation.y) * sign(-viewport_camera.rotation.x)
		_:
			push_error("INVALID_PLANE_AXIS")

	if InputManager.instance.rmb_pressed:
		return

	var snap: bool = AssetPlacerState.instance.snapping_state.is_active
	const CAM_PLANE_DISTANCE_WEIGHT := 3.0
	var distance_factor := 0.0

	if viewport_camera.projection == Camera3D.PROJECTION_PERSPECTIVE:
		distance_factor = CAM_PLANE_DISTANCE_WEIGHT * abs(cam_to_plane_distance)
		var dist := 3.0
		var cam_width_at_dist := tan(deg_to_rad(viewport_camera.fov) / 2.0) * 2.0 * dist
		var cam_world_size := Vector2(cam_width_at_dist, cam_width_at_dist / viewport_camera.get_viewport().get_visible_rect().size.aspect())
		var cam_world_size_world := viewport_camera.basis * Vector3(cam_world_size.x, cam_world_size.y, 0)
		var cam_plane_move_len := PlaneStrategy.get_plane_normal().dot(cam_world_size_world)
		distance_factor = max(distance_factor, cam_plane_move_len)
	else:
		distance_factor = viewport_camera.size

	var step := 0.0
	if snap:
		step = AssetPlacerState.instance.snapping_state.current_step
		distance_factor = max(distance_factor, step)

	var world_pos := _plane_pos_before_move + mouse_diff * distance_factor
	var plane_pos: float = snapped(world_pos, step)
	AssetPlacerState.instance.placement_config_state.plane_position = plane_pos
	Tips.set_tt("plane", "", Tips.TYPE.DEFAULT, 0, true)
	Tips.set_tt("plane/pos", str(plane_pos), Tips.TYPE.VALUE)
	Tips.set_tt("plane/info", Lang.ttr("move_plane"), Tips.TYPE.HINT)


func set_placement_plane_transform(p_viewport_camera: Camera3D) -> void:
	if _plane_gizmo == null:
		return

	_plane_gizmo.rotation = SpatialUtils.get_vector_rotation(Vector3.BACK, PlaneStrategy.get_plane_normal()).get_euler()
	_plane_gizmo.global_position = _plane_strategy.calculate_plane_gizmo_pos(p_viewport_camera)

	var cam_scale := 0.0
	var plane_pos := AssetPlacerState.instance.placement_config_state.plane_position
	if p_viewport_camera.projection == Camera3D.PROJECTION_PERSPECTIVE:
		var distance_fac: float = abs(p_viewport_camera.global_position[PlaneStrategy.get_plane_axis()] - plane_pos)
		var cam_plane_angle := get_cam_plane_angle(-p_viewport_camera.transform.basis.z, PlaneStrategy.get_plane_axis(), plane_pos)
		var angle_fac: float = PI / 2.0 / max(cam_plane_angle, 0.1) * 0.5
		var fov_fac := p_viewport_camera.fov / 10.0
		cam_scale = max(distance_fac, 1.0) * fov_fac * 3.0 * max(angle_fac, 0.1)
	else:
		cam_scale = p_viewport_camera.size

	_plane_gizmo.scale = cam_scale * Vector3.ONE


static func get_cam_plane_angle(p_cam_look_direction: Vector3, p_plane_normal: int, p_plane_height: float) -> float:
	var flat_cam_look_direction := p_cam_look_direction
	flat_cam_look_direction[p_plane_normal] = p_plane_height
	return p_cam_look_direction.angle_to(flat_cam_look_direction)


func _evaluate_expression(p_text: String) -> Array:
	var expr := Expression.new()
	var err := expr.parse(p_text)
	if err == OK:
		var result: Variant = expr.execute([], null, false)
		if not expr.has_execute_failed():
			return [true, result]
	return [false, 0.0]
