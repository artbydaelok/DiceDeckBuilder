extends DirectionalLight3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_x(PI / 16.0 * delta)
