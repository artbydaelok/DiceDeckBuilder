# ray_info.gd
# © Copyright CookieBadger 2026
@tool

const RayInfo = preload("res://addons/assetplacer/viewport_3d_controllers/placement_controller/ray_strategy/ray_info.gd")

enum VALIDITY { VALID, NO_INTERSECTION, NO_SURFACE, TERRAIN_ERROR, TERRAIN_NO_INTERSECTION, INVALID }

var pos := Vector3.ZERO
var normal := Vector3.UP
var validity: VALIDITY = VALIDITY.INVALID
var validity_message: String = ""


func is_valid() -> bool:
	return validity == VALIDITY.VALID


func _init(p_pos: Vector3 = Vector3.ZERO, p_normal: Vector3 = Vector3.UP) -> void:
	self.validity = VALIDITY.VALID
	self.pos = p_pos
	self.normal = p_normal


static func invalid(p_reason: VALIDITY = VALIDITY.INVALID, p_message: String = "") -> RayInfo:
	var info: RayInfo = RayInfo.new(Vector3.ZERO, Vector3.UP)
	info.validity = p_reason
	info.validity_message = p_message
	return info
