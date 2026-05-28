# dynamic_preview_controller.gd
# © Copyright CookieBadger 2026
@tool

const PreviewRenderingViewport = preload("res://addons/assetplacer/asset_palette/preview_generation/preview_rendering_viewport.gd")
const DynamicPreviewView = preload("res://addons/assetplacer/ui/dynamic_preview_view.gd")
const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")

const EPSILON := 1e-4

signal preview_updated(asset_path: String)

var spherical_camera_coordinates: Vector3
var active: bool = false
var has_changed: bool = false

var _target_r: float
var _target_theta: float
var _target_phi: float

var _translation_inertia: float
var _zoom_inertia: float
var _orbit_sensitivity: float  # radians per pixel
var _invert_x_axis: bool
var _invert_y_axis: bool

var _last_orbit_mouse_pos: Vector2
var _orbiting: bool = false

var _dynamic_preview_view: DynamicPreviewView
var _preview_rendering_viewport: PreviewRenderingViewport


func initialize(p_preview_rendering_viewport: PreviewRenderingViewport, p_dynamic_preview_view: DynamicPreviewView) -> void:
	p_preview_rendering_viewport.setup_finished.connect(_on_dynamic_preview_setup_finished)
	_dynamic_preview_view = p_dynamic_preview_view
	_preview_rendering_viewport = p_preview_rendering_viewport
	_dynamic_preview_view.close.connect(_on_preview_closed)
	_dynamic_preview_view.input_event.connect(handle_input)
	_dynamic_preview_view.on_coordinates_edited.connect(_on_coordinates_edited)
	_dynamic_preview_view.initialize(p_preview_rendering_viewport.get_texture())


func show_preview(p_show_over_control: Control, p_asset_node: Node3D, p_perspective: int, p_asset: Asset3DData, p_shadows: bool = false) -> void:
	const DYNAMIC_PREVIEW_SIZE := 512
	_preview_rendering_viewport.size = Vector2i.ONE * DYNAMIC_PREVIEW_SIZE
	_preview_rendering_viewport.set_preview_node(p_asset_node, p_perspective, p_asset.prev_custom_preview, p_shadows)
	_dynamic_preview_view.show_preview(p_show_over_control, p_asset.path.get_file(), p_asset.path)
	_deactivate()  # _deactivate until setup finished (sanity)


func _on_dynamic_preview_setup_finished(p_spherical_camera_coordinates: Vector3) -> void:
	_activate(p_spherical_camera_coordinates)
	_dynamic_preview_view.visible = true


func _activate(p_spherical_camera_coordinates: Vector3) -> void:
	spherical_camera_coordinates = p_spherical_camera_coordinates
	active = true

	_target_r = spherical_camera_coordinates.x
	_target_theta = spherical_camera_coordinates.y
	_target_phi = spherical_camera_coordinates.z

	has_changed = false

	_invert_x_axis = EditorInterface.get_editor_settings().get_setting("editors/3d/navigation/invert_x_axis")
	_invert_y_axis = EditorInterface.get_editor_settings().get_setting("editors/3d/navigation/invert_y_axis")
	_translation_inertia = EditorInterface.get_editor_settings().get_setting("editors/3d/navigation_feel/translation_inertia")
	_zoom_inertia = EditorInterface.get_editor_settings().get_setting("editors/3d/navigation_feel/zoom_inertia")
	_orbit_sensitivity = deg_to_rad(EditorInterface.get_editor_settings().get_setting("editors/3d/navigation_feel/orbit_sensitivity"))


func _on_preview_closed(p_asset_path: String, p_update_preview: bool) -> void:
	_preview_rendering_viewport.free_preview_node()
	_dynamic_preview_view.visible = false
	_deactivate()
	if p_update_preview:
		preview_updated.emit(p_asset_path)


func _deactivate() -> void:
	active = false


func process(p_delta: float) -> void:
	if not active:
		return
	var lerp_t_translation: float = min(1.0, p_delta * (1.0 / _translation_inertia))
	var lerp_t_zoom: float = min(1.0, p_delta * (1.0 / _zoom_inertia))

	var theta: float = lerp(spherical_camera_coordinates.y, _target_theta, lerp_t_translation)
	var phi: float = lerp(spherical_camera_coordinates.z, _target_phi, lerp_t_translation)
	var r: float = lerp(spherical_camera_coordinates.x, _target_r, lerp_t_zoom)

	spherical_camera_coordinates = Vector3(r, theta, phi)

	_preview_rendering_viewport.update_camera_position(spherical_camera_coordinates)


func _on_coordinates_edited(p_spherical_cam_coordinates: Vector3) -> void:
	spherical_camera_coordinates = p_spherical_cam_coordinates
	_target_r = spherical_camera_coordinates.x
	_target_theta = spherical_camera_coordinates.y
	_target_phi = spherical_camera_coordinates.z
	has_changed = true


func handle_input(p_event: InputEvent) -> bool:
	if not active:
		return false

	# mouse motion (orbiting)
	if p_event is InputEventMouseMotion:
		var motion := p_event as InputEventMouseMotion

		# grab focus if mouse passes over panel
		if _dynamic_preview_view.get_global_rect().has_point(motion.global_position):
			_dynamic_preview_view._grab_focus()

		# if already orbiting, focus no longer matters
		if _orbiting and motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			var relative := motion.position - _last_orbit_mouse_pos
			_last_orbit_mouse_pos = motion.position

			if _invert_y_axis:
				_target_theta += relative.y * _orbit_sensitivity
			else:
				_target_theta -= relative.y * _orbit_sensitivity

			_target_theta = clamp(_target_theta, 0.0, PI)

			if _invert_x_axis:
				_target_phi -= relative.x * _orbit_sensitivity
			else:
				_target_phi += relative.x * _orbit_sensitivity

			warp_mouse_in_rect(_dynamic_preview_view.get_global_rect(), motion.global_position)
			has_changed = true
			return true

	if not _dynamic_preview_view._has_focus():
		return false

	# mouse buttons
	if p_event is InputEventMouseButton:
		var button := p_event as InputEventMouseButton

		if button.button_index == MOUSE_BUTTON_MIDDLE and not button.is_echo():
			if button.pressed:
				_last_orbit_mouse_pos = button.position
			_orbiting = button.pressed

		# zoom with wheel
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			on_wheel(-1.0)
			has_changed = true
			return true

		if button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			on_wheel(1.0)
			has_changed = true
			return true

	# trackpad orbiting
	if p_event is InputEventPanGesture:
		var gesture := p_event as InputEventPanGesture

		if _invert_y_axis:
			_target_theta += gesture.delta.y * _orbit_sensitivity
		else:
			_target_theta -= gesture.delta.y * _orbit_sensitivity

		_target_theta = clamp(_target_theta, 0.0, PI)

		if _invert_x_axis:
			_target_phi -= gesture.delta.x * _orbit_sensitivity
		else:
			_target_phi += gesture.delta.x * _orbit_sensitivity

		has_changed = true
		return true

	# pinch zoom
	if p_event is InputEventMagnifyGesture:
		var magnify := p_event as InputEventMagnifyGesture
		on_wheel((1.0 - magnify.factor) * 10.0)
		has_changed = true
		return true

	return false


func warp_mouse_in_rect(p_global_panel_rect: Rect2, p_global_mouse_position: Vector2) -> void:
	var warp := false
	var warp_pos := p_global_mouse_position

	if p_global_mouse_position.x < p_global_panel_rect.position.x:
		warp = true
		warp_pos.x = p_global_panel_rect.position.x + p_global_panel_rect.size.x
		_last_orbit_mouse_pos.x += p_global_panel_rect.size.x
	elif p_global_mouse_position.x > p_global_panel_rect.position.x + p_global_panel_rect.size.x:
		warp = true
		warp_pos.x = p_global_panel_rect.position.x
		_last_orbit_mouse_pos.x -= p_global_panel_rect.size.x

	if p_global_mouse_position.y < p_global_panel_rect.position.y:
		warp = true
		warp_pos.y = p_global_panel_rect.position.y + p_global_panel_rect.size.y
		_last_orbit_mouse_pos.y += p_global_panel_rect.size.y
	elif p_global_mouse_position.y > p_global_panel_rect.position.y + p_global_panel_rect.size.y:
		warp = true
		warp_pos.y = p_global_panel_rect.position.y
		_last_orbit_mouse_pos.y -= p_global_panel_rect.size.y

	if warp:
		Input.warp_mouse(warp_pos)


func on_wheel(p_sign: float) -> void:
	var log_value := log(_target_r)
	log_value = round(log_value * 20.0) / 20.0
	_target_r = clamp(exp(log_value + p_sign * 0.05), 0.2, 1000.0)
