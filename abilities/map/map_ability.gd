extends Ability

## Opens the map UI overlay. Pauses the game while open.
## Closes when the player presses interact/ui_cancel inside the map.

const MAP_DISPLAY = preload("uid://bvgep14qk14it")

func initialize() -> void:
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
