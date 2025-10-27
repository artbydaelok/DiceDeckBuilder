extends Node3D

var start_pos : Vector3
var rand_offset : float

func _ready() -> void:
	start_pos = global_position
	rand_offset = randf() * 100.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position.y = start_pos.y + sin(Time.get_ticks_msec() * 0.00055 + rand_offset) * 2.0
