extends Enemy

# For movement, add a GridMoverComponent child node and configure it in the inspector.
# Connect its step_started / step_finished signals here for animations.

# Called once on spawn
func initialize() -> void:
	pass

# Called when the player starts a move
func _on_player_moved(direction: Vector3) -> void:
	pass

# Called when the player finishes a roll
func _on_player_rolled() -> void:
	pass

# Called every physics frame
func tick(delta: float) -> void:
	pass
