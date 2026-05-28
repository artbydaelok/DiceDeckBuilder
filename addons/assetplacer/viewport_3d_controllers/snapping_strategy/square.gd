# square.gd
# © Copyright CookieBadger 2026
@tool
extends "res://addons/assetplacer/viewport_3d_controllers/snapping_strategy/strategy.gd"

const SpatialUtils = preload("res://addons/assetplacer/utils/spatial_utils.gd")


static func snap_pos_with_offset(pos: Vector3, normal: Vector3, snap_step: float, snap_offset: Vector2) -> Vector3:
	# Get quaternion q that rotates info.normal to Vector3.Up
	var q: Quaternion = SpatialUtils.get_vector_rotation(normal, Vector3.UP)

	# Rotate the placement position by q
	var p_rot := q * pos

	# Get point s_rot that is on same plane as p_rot but with snapped x and z
	var offset := Vector3(snap_offset.x, 0, snap_offset.y)
	var p_rot_offset := p_rot - offset
	var p_snap := p_rot_offset.snapped(Vector3.ONE * snap_step) + offset
	var s_rot := Vector3(p_snap.x, p_rot.y, p_snap.z)

	# Rotate the snapped position back to the original surface plane
	return q.inverse() * s_rot


static func get_translate_offset_from_position(pos: Vector3, plane_pos: Vector3, normal: Vector3, snap_step: float) -> Vector2:
	var isec: Dictionary = SpatialUtils.intersect_plane(normal, plane_pos, normal, pos)
	if not isec["valid"]:
		return Vector2.ZERO
	var projected_pos: Vector3 = isec["intersection"]

	var snapped := snap_pos_with_offset(projected_pos, normal, snap_step, Vector2.ZERO)
	var q: Quaternion = SpatialUtils.get_vector_rotation(normal, Vector3.UP)

	var p_rot := q * projected_pos
	var s_rot := q * snapped

	var proj_to_snapped := p_rot - s_rot
	return Vector2(proj_to_snapped.x, proj_to_snapped.z)
