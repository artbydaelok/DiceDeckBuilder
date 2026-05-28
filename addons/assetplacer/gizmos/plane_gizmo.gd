# plane_gizmo.gd
# © Copyright CookieBadger 2026
@tool
extends MeshInstance3D

const FADE_DURATION := 0.8
const EPSILON := 1e-4

var color := Color("e65c00")
var shader: Shader = load("res://addons/assetplacer/gizmos/alpha_checkerboard.gdshader")

var _material: ShaderMaterial
var _alpha_tweener: Tween


func get_tweening() -> bool:
	return _alpha_tweener != null


func _ready() -> void:
	if not Engine.is_editor_hint():
		return

	mesh = QuadMesh.new()
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("alpha", 1.0)
	_material.set_shader_parameter("color", color)
	_material.set_shader_parameter("checker_alpha", Vector2(0.3, 0.4))
	_material.set_shader_parameter("checker_size", 1.0)
	_material.set_shader_parameter("checker_offset", Vector2.ZERO)

	mesh.surface_set_material(0, _material)
	visible = false


func set_visibility(p_visible_val: bool) -> void:
	if _alpha_tweener == null:
		visible = p_visible_val
		set_alpha(1.0)
	elif p_visible_val:
		set_alpha(1.0)
		visible = true
		_alpha_tweener.kill()
		_alpha_tweener = null


func show_temporarily() -> void:
	if not is_inside_tree():
		return

	visible = true
	_material.set_shader_parameter("alpha", 1.0)

	if _alpha_tweener != null:
		_alpha_tweener.kill()

	_alpha_tweener = create_tween()
	_alpha_tweener.tween_method(Callable(self, "set_alpha"), 1.0, 0.0, FADE_DURATION)
	_alpha_tweener.finished.connect(
		func() -> void:
			visible = false
			_alpha_tweener.kill()
			_alpha_tweener = null
	)


func set_alpha(p_value: float) -> void:
	_material.set_shader_parameter("alpha", p_value)


func set_checker_pattern(p_checker_size: float, p_offset: Vector2) -> void:
	if _material:
		_material.set_shader_parameter("p_checker_size", p_checker_size)
		_material.set_shader_parameter("checker_offset", p_offset)
