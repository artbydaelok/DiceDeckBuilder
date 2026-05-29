@tool
extends Node3D
## Temporary helper — add this scene to a level, configure the exports to match
## your LevelMapData, then click "Save Reference PNG" in the inspector.
## Delete or hide this node before shipping. It does nothing in exported builds.

@export var map_top_left: Vector2 = Vector2(-50, -25)
@export var level_dimensions: Vector2 = Vector2(100, 50)
@export var output_resolution: Vector2i = Vector2i(1024, 512)
## Path inside res:// where the PNG will be saved.
@export_file("*.png") var output_path: String = "res://assets/ui/map_reference.png"

@export_group("Actions")
@export_tool_button("📷  Save Reference PNG", "Camera") var _btn_save = _save_screenshot
@export_tool_button("⟳  Refresh Camera Setup", "Reload") var _btn_refresh = _setup

@onready var _viewport: SubViewport = $SubViewport
@onready var _camera: Camera3D = $SubViewport/Camera3D


func _ready() -> void:
	if Engine.is_editor_hint():
		_setup()


func _setup() -> void:
	if not is_node_ready(): return

	# Position the camera at the centre of the level area, high up, looking down.
	var center_x := map_top_left.x + level_dimensions.x * 0.5
	var center_z := map_top_left.y + level_dimensions.y * 0.5

	_viewport.size = output_resolution
	# Share the parent viewport's 3D world so we see the actual level geometry.
	_viewport.own_world_3d = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	# 'size' is the vertical world-unit extent of the orthographic frustum.
	_camera.size = level_dimensions.y
	_camera.near = 0.1
	_camera.far  = 1200.0
	_camera.global_position = Vector3(center_x, 600.0, center_z)
	_camera.rotation_degrees = Vector3(-90, 0, 0)


func _save_screenshot() -> void:
	if not Engine.is_editor_hint():
		return

	_setup()

	# Wait two frames so the SubViewport has had time to render with the new setup.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	var img: Image = _viewport.get_texture().get_image()
	if img == null:
		push_error("[MapReferenceCamera] Viewport returned null image.")
		return

	var abs_path := ProjectSettings.globalize_path(output_path)
	var err := img.save_png(abs_path)
	if err == OK:
		print("[MapReferenceCamera] ✓ Saved to: ", abs_path)
		# Tell the editor's filesystem about the new file.
		EditorInterface.get_resource_filesystem().scan()
	else:
		push_error("[MapReferenceCamera] Failed to save PNG (error %d)" % err)
