extends Ability

var map_ui 

const MAP_DISPLAY = preload("uid://bvgep14qk14it")

func initialize():
	player.player_moved.connect(_on_player_moved)
	map_ui = MAP_DISPLAY.instantiate()
	
	self_destroy_timer.queue_free()
	
	GameEvents.current_level.ui.add_child(map_ui)

func _on_player_moved(direction):
	# When the player moves, the map ui is freed alongside this ability node.
	map_ui.queue_free()
	queue_free()
