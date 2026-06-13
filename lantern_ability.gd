extends Ability
## Lantern.
##   PRIMARY   (LMB / A) → a light that floats above you for a while.
##   SECONDARY (RMB / B) → leave a lantern behind where you stand; it stays until you
##                         place another. Both grant a small (non-stacking) move-speed
##                         boost while active.

const PLACED_HEIGHT := 1.5

@onready var lantern_mesh: Node3D = $LanternMesh

var _speed_added := false


func initialize():
	if is_secondary:
		_leave_behind()
	_grant_speed()


func tick(delta):
	if not is_secondary:
		lantern_mesh.global_position = player.mesh.global_position + Vector3(0, 3, 0)


## Drop the lantern where the player stands and keep it there (persist + detach).
func _leave_behind():
	if is_instance_valid(player.placed_lantern):
		player.placed_lantern.queue_free()   # only one placed lantern at a time
	player.placed_lantern = self
	if self_destroy_timer != null:
		self_destroy_timer.queue_free()       # persist instead of auto-destroying
	lantern_mesh.global_position = Vector3(player.global_position.x, PLACED_HEIGHT, player.global_position.z)
	reparent(entities_layer)                  # detach from the player so it stays put


func _grant_speed():
	if not _speed_added and player != null:
		player.add_lantern_speed()
		_speed_added = true


# Remove the speed bonus only on actual deletion (NOT on the reparent above, which
# would otherwise fire EXIT_TREE).
func _notification(what):
	if what == NOTIFICATION_PREDELETE and _speed_added and is_instance_valid(player):
		player.remove_lantern_speed()
