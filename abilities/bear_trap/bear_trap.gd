extends Ability

const BEAR_TRAP_PROJECTILE = preload("uid://bxvgkg8b168o")
var bear_trap_proj

func initialize():
	self_destroy_timer.queue_free()
	bear_trap_proj = BEAR_TRAP_PROJECTILE.instantiate()
	GameEvents.current_level.add_child(bear_trap_proj)
	bear_trap_proj.global_position = player.global_position + Vector3(0, 2.5, 0)
	player.player_moved.connect(_on_player_moved)
	
func _on_player_moved(dir):
	bear_trap_proj.activate()
	queue_free()
