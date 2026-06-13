extends Ability
## Map.
##   PRIMARY   (LMB / A) → open the map UI overlay (pauses; closes on interact/cancel).
##   SECONDARY (RMB / B) → Recall marker: press once to drop a marker where you stand
##                         (remembering the camera zone); press again to warp back to it.

const MAP_DISPLAY = preload("uid://bvgep14qk14it")

const MARKER_COLOR := Color(0.2, 0.8, 1.0)


func initialize() -> void:
	if is_secondary:
		self_destroy_timer.queue_free()
		_recall()
		queue_free()
		return

	# Primary: open the map overlay.
	# Don't use the default self-destroy timer — we control our own lifetime.
	self_destroy_timer.queue_free()

	if GameEvents.current_level.current_map_data == null:
		push_warning("map_ability: no map data on current level.")
		queue_free()
		return

	var map_ui = MAP_DISPLAY.instantiate()
	GameEvents.current_level.ui.add_child(map_ui)

	# Destroy this ability node once the map UI closes.
	map_ui.tree_exited.connect(queue_free)


## No marker yet → drop one (remembering the camera zone). Marker exists → warp to it.
func _recall() -> void:
	if player.recall_marker.is_empty():
		_drop_marker()
	else:
		_warp_to_marker()


func _drop_marker() -> void:
	var marker := _spawn_marker(player.global_position)
	player.recall_marker = {
		"position": player.global_position,
		"x_grid": player.x_grid_pos,
		"y_grid": player.y_grid_pos,
		"zone": CameraZoneManager.get_active_zone(),
		"marker": marker,
	}


func _warp_to_marker() -> void:
	var m: Dictionary = player.recall_marker

	# Teleport the player back.
	player.global_position = m["position"]
	player.x_grid_pos = m["x_grid"]
	player.y_grid_pos = m["y_grid"]
	player.grid_pos = Vector2(player.x_grid_pos, player.y_grid_pos)

	# Restore the camera zone we were in when the marker was dropped.
	var zone = m.get("zone")
	if zone != null and is_instance_valid(zone):
		CameraZoneManager.enter_zone(zone)

	# Clear the marker.
	var marker = m.get("marker")
	if is_instance_valid(marker):
		marker.queue_free()
	player.recall_marker = {}


## A tall glowing beacon at the recall spot.
func _spawn_marker(pos: Vector3) -> Node3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 4.0, 0.3)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = MARKER_COLOR
	mat.emission_enabled = true
	mat.emission = MARKER_COLOR
	mat.emission_energy_multiplier = 2.0
	mi.material_override = mat
	entities_layer.add_child(mi)
	mi.global_position = Vector3(pos.x, 2.0, pos.z)  # stands on the ground
	return mi
