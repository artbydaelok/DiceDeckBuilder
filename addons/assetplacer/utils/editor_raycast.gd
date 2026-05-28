# editor_raycast.gd
# © Copyright CookieBadger 2026
@tool

const Settings = preload("res://addons/assetplacer/settings.gd")

const RAYCAST_LENGTH_PERSPECTIVE := 500.0
const RAYCAST_LENGTH_ORTHOGONAL := 100000.0  # needs to be this high

var _from: Vector3
var _dir: Vector3
var _length: float


func _init(p_from: Vector3, p_dir: Vector3, p_cam_projection: Camera3D.ProjectionType) -> void:
	_from = p_from
	_dir = p_dir

	match p_cam_projection:
		Camera3D.PROJECTION_ORTHOGONAL:
			_length = RAYCAST_LENGTH_ORTHOGONAL
		_:
			_length = RAYCAST_LENGTH_PERSPECTIVE


func perform_raycast(p_world: World3D, p_placing_nodes: Array[Node3D]) -> Dictionary:
	var space_state := p_world.direct_space_state

	var exclusion := EditorRaycast3DExclusion.new(p_placing_nodes)
	exclusion.prepare()

	var ray_params := PhysicsRayQueryParameters3D.create(_from, _from + _dir * _length, Settings.get_setting(Settings.DEFAULT_CATEGORY, Settings.SURFACE_COLLISION_MASK), exclusion.excluded_rids)

	var result := space_state.intersect_ray(ray_params)
	exclusion.restore()
	return result


class EditorRaycast3DExclusion:
	var excluded_rids: Array[RID]
	var excluded_csgs: Array[CSGShape3D]
	var grid_map_exclusions: Dictionary[GridMap, int]

	func _init(p_excluded_nodes: Array[Node3D]) -> void:
		var rid_list: Array[RID] = []
		excluded_csgs = []
		grid_map_exclusions = {}

		# exclude the hologram and assets that have just been painted from the raycast to avoid undesired results
		for n in p_excluded_nodes:
			add_exclusions_recursive(n, rid_list)

		excluded_rids = rid_list

	func add_exclusions_recursive(p_current: Node, p_rid_list: Array[RID]) -> void:
		if p_current is CollisionObject3D:
			p_rid_list.push_back(p_current.get_rid())
		elif p_current is SoftBody3D:
			p_rid_list.push_back(p_current.get_physics_rid())
		elif p_current is CSGShape3D and p_current.use_collision:
			excluded_csgs.push_back(p_current)
		elif p_current is GridMap:
			grid_map_exclusions[p_current as GridMap] = p_current.collision_layer

		for child in p_current.get_children():
			add_exclusions_recursive(child, p_rid_list)

	func prepare() -> void:
		# disable csg collisions
		for c in excluded_csgs:
			c.use_collision = false

		for grid_map: Node in grid_map_exclusions.keys():
			grid_map.collision_layer = 0

	func restore() -> void:
		# re-enable csg collisions
		for c in excluded_csgs:
			c.use_collision = true

		for grid_map in grid_map_exclusions:
			grid_map.collision_layer = grid_map_exclusions[grid_map]
