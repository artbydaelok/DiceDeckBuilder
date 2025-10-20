@tool
extends Camera3D

@export var random_strength : float = 0.35	
@export var shake_fade : float = 2.5
@export var is_shake_one_shot : bool = false

var rng = RandomNumberGenerator.new()


@export var shake_strength: float = 0.0

func _process(delta: float) -> void:
	if shake_strength > 0:
		if is_shake_one_shot:
			shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		var r_offset = random_offset()
		h_offset = r_offset.x
		v_offset = r_offset.y

func random_offset() -> Vector2:
	return Vector2(
		rng.randf_range(-shake_strength, shake_strength), # x
		rng.randf_range(-shake_strength, shake_strength)) # y
