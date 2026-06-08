extends Ability
## Bear Trap.
##   PRIMARY   (LMB / A) → arm a trap; it drops behind you when you next move and
##                         captures the capturable enemy that triggers it.
##   SECONDARY (RMB / B) → Trap Release: re-summon the captured creature in front of
##                         you as a one-shot charging ally (see Enemy.release_charge()).
## CardSystem gates the release so an empty trap costs nothing.

const BEAR_TRAP_PROJECTILE = preload("uid://bxvgkg8b168o")
var bear_trap_proj

func initialize():
	if is_secondary:
		_release()
		return

	self_destroy_timer.queue_free()
	bear_trap_proj = BEAR_TRAP_PROJECTILE.instantiate()
	GameEvents.current_level.add_child(bear_trap_proj)
	bear_trap_proj.global_position = player.global_position + Vector3(0, 2.5, 0)
	player.player_moved.connect(_on_player_moved)

func _on_player_moved(dir):
	bear_trap_proj.activate()
	queue_free()


## Re-summon the captured creature in front of the player as a charging ally.
func _release() -> void:
	if player.captured_creature.is_empty():
		return
	var scene_path: String = player.captured_creature.get("scene_path", "")
	player.captured_creature = {}  # consume the capture
	if scene_path == "":
		return
	var scene = load(scene_path)
	if scene == null:
		return
	var ally = scene.instantiate()
	if "is_ally" in ally:
		ally.is_ally = true
	get_tree().get_first_node_in_group("entities_layer").add_child(ally)
	ally.global_position = player.global_position + Vector3(0, 0, -2.0)  # one tile in front
	if ally.has_method("release_charge"):
		ally.release_charge()
