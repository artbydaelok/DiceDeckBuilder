# line_gizmo.gd
# © Copyright CookieBadger 2026
@tool
extends MeshInstance3D


func create_mesh() -> void:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	surface_tool.add_vertex(Vector3(0.0, -0.5, 0.0))
	surface_tool.add_vertex(Vector3(0.0, 0.5, 0.0))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 1.0, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	surface_tool.set_material(mat)
	mesh = surface_tool.commit()
