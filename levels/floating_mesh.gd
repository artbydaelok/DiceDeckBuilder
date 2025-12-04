extends Node3D

var start_pos : Vector3
var rand_offset : float

@export var anim_amount : float = 2.0
@export var random_rotation_animation : Vector3 = Vector3.ZERO

func _ready() -> void:
	start_pos = global_position
	rand_offset = randf() * 100.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position.y = start_pos.y + sin(Time.get_ticks_msec() * 0.00055 + rand_offset) * anim_amount
	rotation += random_rotation_animation * delta

#TODO Need to add particles
