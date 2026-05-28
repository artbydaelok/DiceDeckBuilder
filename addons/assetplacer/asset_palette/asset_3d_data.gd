# asset_3d_data.gd
# © Copyright CookieBadger 2026
@tool
extends Object

const PERSPECTIVE_ENUM_STRING: String = "Front:1,Back:2,Top:3,Bottom:4,Left:5,Right:6"

# Perspective Setting
enum PreviewPerspective { DEFAULT, FRONT, BACK, TOP, BOTTOM, LEFT, RIGHT, CUSTOM }

var default_transform: Transform3D = Transform3D.IDENTITY  # used for resetting transform. Set when asset is instantiated.
var current_transform: Transform3D = Transform3D.IDENTITY
# reason why we don't just set current_transform = default_transform when we spawn a new node, is such that we don't reset old transform
var current_transform_valid: bool = false
var path: String
var is_mesh: bool
var preview_perspective: PreviewPerspective = PreviewPerspective.DEFAULT
var custom_preview := Vector3(1.0, PI / 2.0, 0.0)  # polar coordinates. default: straight front view at 1m distance
var prev_custom_preview := -Vector3.ONE  # negative: invalid
var is_broken: bool = false
var preview_texture: Texture2D = null

var generated_preview_perspective := PreviewPerspective.DEFAULT  # for testing. Default = not generated yet
var generated_custom_preview := -Vector3.ONE


func _init(
	p_path: String, p_perspective: PreviewPerspective, p_custom_preview: Vector3, p_is_mesh: bool = false, p_transform: Transform3D = Transform3D.IDENTITY, p_transform_valid: bool = false
) -> void:
	self.path = p_path
	self.preview_perspective = p_perspective
	self.custom_preview = p_custom_preview
	self.is_mesh = p_is_mesh
	if p_transform_valid:
		self.current_transform = p_transform
		self.current_transform_valid = p_transform_valid
