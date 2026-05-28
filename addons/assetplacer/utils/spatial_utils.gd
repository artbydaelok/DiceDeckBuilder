# spatial_utils.gd
# © Copyright CookieBadger 2026
const EPSILON := 1e-6

const ALIGN_AXES: Dictionary[int, String] = {
	AlignAxis.RIGHT: "+X (Right)", AlignAxis.LEFT: "-X (Left)", AlignAxis.UP: "+Y (Up)", AlignAxis.DOWN: "-Y (Down)", AlignAxis.FORWARD: "+Z (Forward)", AlignAxis.BACK: "-Z (Back)"
}

enum AlignAxis { RIGHT = 0, LEFT = 1, UP = 2, DOWN = 3, FORWARD = 4, BACK = 5 }


static func organize_spatial_children(p_root: Node3D) -> void:
	# measure all assets
	var total_area := 0.0
	var total_size := Vector3.ZERO
	var node_aabbs: Dictionary[Node3D, AABB] = {}
	var asset_count := 0

	for node in p_root.get_children():
		if node is Node3D:
			var node_3d := node as Node3D
			var aabb := get_global_aabb(node)
			total_area += aabb.size.x * aabb.size.z
			total_size += aabb.size
			node_aabbs[node_3d] = aabb
			asset_count += 1

	if asset_count == 0:
		return

	# position all assets
	var average_asset_x := total_size.x / asset_count
	var average_asset_z := total_size.z / asset_count
	var padding_x := average_asset_x / 2.0
	var padding_z := average_asset_z / 2.0
	var tight_row_length := sqrt(total_area)
	var desired_assets_per_row := tight_row_length / average_asset_x
	var desired_assets_per_column := asset_count / desired_assets_per_row
	var desired_row_length := tight_row_length + (desired_assets_per_row - 1.0) * padding_x
	var desired_z := desired_assets_per_column * average_asset_z + (desired_assets_per_column - 1.0) * padding_z

	var current_row_depth := 0.0
	var x := 0.0
	var z := 0.0

	for node: Node3D in node_aabbs.keys():
		if x > desired_row_length:
			z += current_row_depth + padding_z
			x = 0.0
			current_row_depth = 0.0

		var size_x := node_aabbs[node].size.x
		var size_z := node_aabbs[node].size.z
		var position := Vector3(-desired_row_length / 2.0 + x, 0.0, -desired_z / 2.0 + z)

		var center := node_aabbs[node].get_center()
		node.position = position - Vector3(center.x, 0.0, center.z) + Vector3(size_x / 2.0, 0.0, size_z / 2.0)

		x += size_x + padding_x
		current_row_depth = max(size_z, current_row_depth)


static func get_global_aabb(p_root: Node) -> AABB:
	var endpoints: Array[Vector3] = []
	get_aabb_endpoints_recursive(p_root, endpoints)

	var start := Vector3.ZERO
	var end := Vector3.ZERO

	if endpoints.size() > 0:
		start = endpoints[0]
		end = endpoints[0]

	for endpoint in endpoints:
		if endpoint.x < start.x:
			start.x = endpoint.x
		if endpoint.y < start.y:
			start.y = endpoint.y
		if endpoint.z < start.z:
			start.z = endpoint.z

		if endpoint.x > end.x:
			end.x = endpoint.x
		if endpoint.y > end.y:
			end.y = endpoint.y
		if endpoint.z > end.z:
			end.z = endpoint.z

	return AABB(start, end - start)


static func get_aabb_endpoints_recursive(p_current_node: Node, r_endpoints: Array[Vector3]) -> void:
	if p_current_node is VisualInstance3D:
		var global_aabb_endpoints := get_global_aabb_endpoints(p_current_node)
		r_endpoints.append_array(global_aabb_endpoints)

	for child in p_current_node.get_children():
		get_aabb_endpoints_recursive(child, r_endpoints)


static func get_global_aabb_endpoints(p_visual_instance_3d: VisualInstance3D) -> Array[Vector3]:
	var global_endpoints: Array[Vector3] = []
	global_endpoints.resize(8)

	var local_aabb := p_visual_instance_3d.get_aabb()
	for i in range(8):
		var local_endpoint := local_aabb.get_endpoint(i)
		var global_endpoint := p_visual_instance_3d.to_global(local_endpoint)
		global_endpoints[i] = global_endpoint

	return global_endpoints


static func get_align_axis(p_transform: Transform3D, p_align_axis: int) -> Vector3:
	match p_align_axis:
		AlignAxis.RIGHT:
			return p_transform.basis.x  # left
		AlignAxis.LEFT:
			return -p_transform.basis.x  # right
		AlignAxis.UP:
			return p_transform.basis.y  # up
		AlignAxis.DOWN:
			return -p_transform.basis.y  # down
		AlignAxis.FORWARD:
			return p_transform.basis.z  # back
		AlignAxis.BACK:
			return -p_transform.basis.z  # forward
		_:
			return p_transform.basis.y  # default up


static func align(p_transform: Transform3D, p_current_dir: Vector3, p_target_dir: Vector3) -> Transform3D:
	var vec := p_current_dir.normalized()
	p_target_dir = p_target_dir.normalized()

	if p_target_dir.distance_squared_to(vec) < 0.001:
		return p_transform

	var cos_a := vec.dot(p_target_dir)
	var alpha := acos(clamp(cos_a, -1.0, 1.0))

	# Vectors are parallel
	if abs(fmod(alpha, PI)) < 0.001:
		return p_transform.rotated(p_transform.basis.x.normalized(), alpha)

	var axis := vec.cross(p_target_dir)
	axis = axis.normalized()

	return p_transform.rotated(axis, alpha)


static func get_vector_rotation(p_from: Vector3, p_to: Vector3) -> Quaternion:
	p_from = p_from.normalized()
	p_to = p_to.normalized()
	var dot := p_from.dot(p_to)
	if dot > 1.0 - EPSILON:
		return Quaternion.IDENTITY

	if dot < -(1.0 - EPSILON):
		var normal := Vector3.UP.cross(p_from)
		if normal.length_squared() < EPSILON:
			normal = Vector3.RIGHT.cross(p_from)
		return Quaternion(normal.normalized(), PI)

	var axis := p_from.cross(p_to)
	var angle := 1.0 + dot

	var q := Quaternion()
	q.x = axis.x
	q.y = axis.y
	q.z = axis.z
	q.w = angle
	return q.normalized()


## intersects a line with normalized line_dir and point line_point through the plane which has plane_point and plane_normal
## returns a dictionary with entries "valid": bool and "intersection": Vector3
static func intersect_plane(p_plane_normal: Vector3, p_plane_point: Vector3, p_line_dir: Vector3, p_line_point: Vector3) -> Dictionary:
	var ret := {"valid": false, "intersection": Vector3.ZERO}

	var n_dot_u := p_plane_normal.dot(p_line_dir)

	if abs(n_dot_u) > EPSILON:
		var w := p_plane_normal.dot(p_plane_point - p_line_point)
		var d := -w / n_dot_u
		ret["valid"] = true
		ret["intersection"] = p_line_point + d * p_line_dir

	return ret


static func are_xforms_equal_approx(p_t1: Transform3D, p_t2: Transform3D) -> bool:
	return p_t1.basis.is_equal_approx(p_t2.basis) and are_vecs_equal_approx(p_t1.origin, p_t2.origin)


static func are_vecs_equal_approx(p_v1: Vector3, p_v2: Vector3) -> bool:
	var diff := p_v1 - p_v2
	const POSITION_PRECISION = 0.0003
	return abs(diff.x) < POSITION_PRECISION and abs(diff.y) < POSITION_PRECISION and abs(diff.z) < POSITION_PRECISION


## Set the camera position in the editor viewport. Rotation is in polar coordinates (degrees),
## i.e. rotation_degrees.x is the polar angle (angle from positive y-axis) and
## rotation_degrees.y is the azimuthal angle (angle from positive x-axis = rotation around y-axis; clockwise when looking from above).
static func look_at_polar(lookat: Vector3, distance: float, rotation_degrees: Vector2) -> Transform3D:
	var rotation_radians := Vector2(deg_to_rad(rotation_degrees.x), deg_to_rad(rotation_degrees.y))
	var rot_x := Basis(Vector3(1, 0, 0), deg_to_rad(-90 + rotation_degrees.x))
	var rot_y := Basis(Vector3(0, 1, 0), rotation_radians.y)
	var rot := rot_y * rot_x

	var unit_sphere_pos := Vector3(sin(rotation_radians.x) * sin(rotation_radians.y), cos(rotation_radians.x), sin(rotation_radians.x) * cos(rotation_radians.y))
	var pos := unit_sphere_pos * distance + lookat
	return Transform3D(rot, pos)
