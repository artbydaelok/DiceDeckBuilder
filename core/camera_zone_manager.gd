extends Node

const ACTIVE_PRIORITY := 10
const INACTIVE_PRIORITY := -1

var _default_zone

var _zone_stack: Array = []

func enter_zone(zone: Node) -> void:
	_zone_stack.erase(zone)       # prevent duplicates if re-entered
	_zone_stack.append(zone)
	_refresh()

func exit_zone(zone: Node) -> void:
	zone.phantom_camera.priority = INACTIVE_PRIORITY
	_zone_stack.erase(zone)
	_refresh()

## Call this from DialogueManager or any global when a scripted sequence ends.
func release_active_zone() -> void:
	if _zone_stack.is_empty():
		return
	var zone = _zone_stack.back()
	zone.monitoring = false
	exit_zone(zone)

func _refresh() -> void:
	for zone in _zone_stack:
		zone.phantom_camera.priority = INACTIVE_PRIORITY
	if not _zone_stack.is_empty():
		_zone_stack.back().phantom_camera.priority = ACTIVE_PRIORITY
	elif _default_zone != null:
		_default_zone.phantom_camera.priority = ACTIVE_PRIORITY

func set_default_zone(zone):
	_default_zone = zone
