# grid_gizmo.gd
# © Copyright CookieBadger 2026
@tool
extends MeshInstance3D

var distance_fade_shader: Shader = load("res://addons/assetplacer/gizmos/grid_distance_fade.gdshader")

var line_cnt: int
var line_spacing: float

var _distance_fade_mat: ShaderMaterial


func create_mesh(p_color: Color) -> void:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.TRANSPARENT
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_distance_fade_mat = ShaderMaterial.new()
	_distance_fade_mat.shader = distance_fade_shader
	mat.next_pass = _distance_fade_mat

	var line_len := line_cnt * line_spacing
	_distance_fade_mat.set_shader_parameter("line_len", line_len)
	_distance_fade_mat.set_shader_parameter("grid_color", p_color)

	surface_tool.set_material(mat)

	@warning_ignore_start("integer_division")
	# parallel to Z axis
	for i in line_cnt:
		#surface_tool.set_normal(Vector3(0, 1, 0))
		surface_tool.add_vertex(Vector3((-line_cnt / 2 + i) * line_spacing, 0, -line_len / 2))
		#surface_tool.set_normal(Vector3(0, 1, 0))
		surface_tool.add_vertex(Vector3((-line_cnt / 2 + i) * line_spacing, 0, line_len / 2))

	# parallel to X axis
	for i in line_cnt:
		#surface_tool.set_normal(Vector3(0, 1, 0))
		surface_tool.add_vertex(Vector3(-line_len / 2, 0, (-line_cnt / 2 + i) * line_spacing))
		#surface_tool.set_normal(Vector3(0, 1, 0))
		surface_tool.add_vertex(Vector3(line_len / 2, 0, (-line_cnt / 2 + i) * line_spacing))
	@warning_ignore_restore("integer_division")

	self.mesh = surface_tool.commit()


func get_color() -> Color:
	if _distance_fade_mat:
		return _distance_fade_mat.get_shader_parameter("grid_color")
	return Color.WHITE


func set_color(p_color: Color) -> void:
	if _distance_fade_mat:
		_distance_fade_mat.set_shader_parameter("grid_color", p_color)


func update_cam(p_is_perspective: bool) -> void:
	if _distance_fade_mat:
		_distance_fade_mat.set_shader_parameter("p_is_perspective", p_is_perspective)
