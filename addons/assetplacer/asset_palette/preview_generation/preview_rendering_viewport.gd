# preview_rendering_viewport.gd
# © Copyright CookieBadger 2026
@tool
extends SubViewport

const PreviewCamera3D = preload("res://addons/assetplacer/asset_palette/preview_generation/preview_camera_3d.gd")
const SpatialUtils = preload("res://addons/assetplacer/utils/spatial_utils.gd")
const Settings = preload("res://addons/assetplacer/settings.gd")
const AssetPreviewGenerator = preload("res://addons/assetplacer/asset_palette/preview_generation/asset_preview_generator.gd")
const Asset3DData = preload("res://addons/assetplacer/asset_palette/asset_3d_data.gd")

const EPSILON := 1e-4

signal setup_finished(spherical_camera_coordinates: Vector3)

@export var camera: PreviewCamera3D
@export var light: Light3D
@export var light_2: Light3D
@export var light_3: Light3D

var is_idle: bool = true

var preview_node: Node

var is_preview_ready := false
var perspective_preset := Asset3DData.PreviewPerspective.FRONT

# spherical coordinates:
# x = distance (r)
# y = theta
# z = phi
var spherical_camera_position: Vector3
var camera_transform: Transform3D
var aabb: AABB

var updates := 0


func _ready() -> void:
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	render_target_update_mode = SubViewport.UPDATE_DISABLED

	camera.preview_ready.connect(_on_camera_preview_ready)


func free_preview_node() -> void:
	if preview_node:
		preview_node.queue_free()
	preview_node = null
	render_target_update_mode = SubViewport.UPDATE_DISABLED


func set_preview_node(p_preview_node: Node3D, p_perspective: Asset3DData.PreviewPerspective, p_spherical_cam_pos: Vector3, p_shadows: bool = false) -> void:
	perspective_preset = p_perspective
	spherical_camera_position = p_spherical_cam_pos

	_preview_node_setup(p_preview_node, p_shadows)
	render_target_update_mode = SubViewport.UPDATE_ALWAYS


func update_camera_position(spherical_cam_pos: Vector3) -> void:
	camera.transform = build_camera_transform(aabb, spherical_cam_pos)


func _preview_node_setup(p_node: Node, p_shadows: bool) -> void:
	updates = 0
	preview_node = Node3D.new()
	preview_node.add_child(p_node)

	is_preview_ready = false
	preview_node.ready.connect(_reposition_camera)

	light.shadow_enabled = p_shadows

	# Defer so _ready() is not called instantly
	add_child.call_deferred(preview_node)


func _reposition_camera() -> void:
	if preview_node == null:
		return

	aabb = SpatialUtils.get_global_aabb(preview_node)

	var transform: Transform3D
	if perspective_preset == Asset3DData.PreviewPerspective.CUSTOM:
		transform = build_camera_transform(aabb, spherical_camera_position)
	else:
		transform = calculate_camera_transform_from_preset(aabb, perspective_preset)
		spherical_camera_position = cartesian_to_spherical(transform.origin - aabb.get_center(), transform.basis.get_euler())

	camera.start_preview(transform)

	light.quaternion = camera.quaternion * Quaternion.from_euler(Vector3(-1.047198, 0.7853982, 0.0))
	light_2.quaternion = camera.quaternion * Quaternion.from_euler(Vector3(-0.2617994, -0.7853982, 2.007129))
	light_3.quaternion = camera.quaternion * Quaternion.from_euler(Vector3(0.2617994, 2.356194, 2.007129))

	setup_finished.emit(spherical_camera_position)


func _on_camera_preview_ready() -> void:
	is_preview_ready = true


# --- Static helpers ---


static func build_camera_transform(p_aabb: AABB, p_s_cam_pos: Vector3) -> Transform3D:
	var relative_position := spherical_to_cartesian(p_s_cam_pos)
	var position := p_aabb.get_center() + relative_position

	if abs(relative_position.length_squared()) < EPSILON:
		return Transform3D(Basis.IDENTITY, position)

	var basis := look_at(relative_position.normalized(), p_s_cam_pos.z)
	return Transform3D(basis, position)


func calculate_camera_transform_from_preset(p_aabb: AABB, p_perspective: int) -> Transform3D:
	var enclosing_square := get_aabb_enclosing_square_size(p_aabb, p_perspective)

	const SIZE_R_LERP_MIN := 0.1
	const SIZE_R_LERP_MAX := 100.0

	var range_val: float = clamp(enclosing_square, SIZE_R_LERP_MIN, SIZE_R_LERP_MAX)
	var log_range_val := log_lerp(SIZE_R_LERP_MIN, SIZE_R_LERP_MAX, range_val)
	var object_size_factor: float = lerp(0.5, 2.5, 1.0 - log_range_val)

	var distance: float = (get_aabb_depth(p_aabb, p_perspective) / 2.0) + (enclosing_square / 2.0) * object_size_factor

	var s_cam_pos := get_spherical_coords(distance, p_perspective)
	var relative_position := spherical_to_cartesian(s_cam_pos)
	var position := p_aabb.get_center() + relative_position

	if abs(relative_position.length_squared()) < EPSILON:
		return Transform3D(Basis.IDENTITY, position)

	var basis := look_at(relative_position.normalized(), s_cam_pos.z)
	return Transform3D(basis, position)


static func get_spherical_coords(p_distance: float, p_perspective: int) -> Vector3:
	var horizontal_degrees: float = Settings.get_setting(Settings.DEFAULT_CATEGORY, AssetPreviewGenerator.PERSPECTIVE_ANGLE_HORIZONTAL_SETTING)
	var vertical_degrees: float = Settings.get_setting(Settings.DEFAULT_CATEGORY, AssetPreviewGenerator.PERSPECTIVE_ANGLE_VERTICAL_SETTING)

	var horizontal_angle := deg_to_rad(horizontal_degrees)
	var vertical_angle := deg_to_rad(vertical_degrees)

	match p_perspective:
		Asset3DData.PreviewPerspective.FRONT:
			return Vector3(p_distance, PI / 2.0 - vertical_angle, PI / 2.0 - horizontal_angle)
		Asset3DData.PreviewPerspective.BACK:
			return Vector3(p_distance, PI / 2.0 - vertical_angle, -PI / 2.0 - horizontal_angle)
		Asset3DData.PreviewPerspective.LEFT:
			return Vector3(p_distance, PI / 2.0 - vertical_angle, PI - horizontal_angle)
		Asset3DData.PreviewPerspective.RIGHT:
			return Vector3(p_distance, PI / 2.0 - vertical_angle, -horizontal_angle)
		Asset3DData.PreviewPerspective.TOP:
			return Vector3(p_distance, 0.0, PI / 2.0)
		Asset3DData.PreviewPerspective.BOTTOM:
			return Vector3(p_distance, PI, PI / 2.0)
		_:
			return Vector3.ZERO


static func look_at(p_back: Vector3, p_phi: float) -> Basis:
	var up := Vector3.UP
	if p_back.is_equal_approx(Vector3.UP):
		up = Vector3.FORWARD
	if p_back.is_equal_approx(Vector3.DOWN):
		up = Vector3.BACK

	var right := up.cross(p_back)

	if p_back.is_equal_approx(Vector3.UP) or p_back.is_equal_approx(Vector3.DOWN):
		right = right.rotated(Vector3.UP, -p_phi + PI / 2.0)

	return Basis(right, p_back.cross(right), p_back)


static func spherical_to_cartesian(p_spherical: Vector3) -> Vector3:
	return Vector3(sin(p_spherical.y) * cos(p_spherical.z), cos(p_spherical.y), sin(p_spherical.y) * sin(p_spherical.z)) * p_spherical.x


static func cartesian_to_spherical(p_cartesian: Vector3, p_rotation: Vector3) -> Vector3:
	var length := p_cartesian.length()
	if abs(length) < EPSILON:
		return Vector3(length, p_rotation.x + PI / 2.0, -p_rotation.y + PI / 2.0)

	var plane_len := Vector2(p_cartesian.x, p_cartesian.z).length()
	if abs(plane_len) < EPSILON:
		return Vector3(length, 0.0 if p_cartesian.y > 0.0 else PI, -p_rotation.y + PI / 2.0)

	return Vector3(length, acos(p_cartesian.y / length), sign(p_cartesian.z) * acos(p_cartesian.x / plane_len))


static func get_aabb_depth(p_aabb: AABB, p_perspective: int) -> float:
	match p_perspective:
		Asset3DData.PreviewPerspective.FRONT, Asset3DData.PreviewPerspective.BACK:
			return p_aabb.size.z
		Asset3DData.PreviewPerspective.TOP, Asset3DData.PreviewPerspective.BOTTOM:
			return p_aabb.size.y
		Asset3DData.PreviewPerspective.LEFT, Asset3DData.PreviewPerspective.RIGHT:
			return p_aabb.size.x
		_:
			return 0.0


static func get_aabb_enclosing_square_size(p_aabb: AABB, p_perspective: int) -> float:
	match p_perspective:
		Asset3DData.PreviewPerspective.FRONT, Asset3DData.PreviewPerspective.BACK:
			return max(p_aabb.size.x, p_aabb.size.y)
		Asset3DData.PreviewPerspective.TOP, Asset3DData.PreviewPerspective.BOTTOM:
			return max(p_aabb.size.x, p_aabb.size.z)
		Asset3DData.PreviewPerspective.LEFT, Asset3DData.PreviewPerspective.RIGHT:
			return max(p_aabb.size.y, p_aabb.size.z)
		_:
			return 0.0


static func log_lerp(p_min_val: float, p_max_val: float, p_value: float) -> float:
	var p := pow(10.0, -log(p_min_val))
	return log(p_value * p) / log(p_max_val * p)
