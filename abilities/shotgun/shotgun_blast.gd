extends Ability
## Shotgun Blast — a stateful weapon with one loaded shell at a time.
##   PRIMARY   (LMB / A) → fire 2 pellets forward + recoil-slide back one tile, then SPENT.
##   SECONDARY (RMB / B) → Reload the spent shell (simple timed reload) so it can fire again.
## Moving also reloads it (see CardSystem._on_roll_finished). The loaded/spent gate
## lives in CardSystem.play_ability_for_slot so a spent click never wastes energy.

const SHOTGUN_ANIMATION = preload("res://abilities/shotgun/shotgun_animation.tscn")

const RELOAD_TIME := 0.7   # simple timed reload — later this becomes the active-reload micro-game


func initialize():
	if is_secondary:
		_reload()
		return

	# Primary fire: pellets + recoil.
	var shotgun = SHOTGUN_ANIMATION.instantiate()
	entities_layer.add_child(shotgun)
	shotgun.global_position = player.global_position + Vector3(0, 3.5, 0)
	player.shotgun_loaded = false          # spend the shell
	player.knockback(Vector3.BACK)         # recoil one tile back, keeps the up-face


## Simple timed reload — after a short beat the shell is loaded again.
func _reload() -> void:
	await get_tree().create_timer(RELOAD_TIME).timeout
	if is_instance_valid(player):
		player.shotgun_loaded = true
