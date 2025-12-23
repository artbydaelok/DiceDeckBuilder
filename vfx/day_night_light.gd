extends DirectionalLight3D

@export_range(0.5, 5.0, 0.01) var speed_mult = 1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_x(PI / 16.0 * delta * speed_mult)
