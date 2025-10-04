extends Camera3D

@export var random_strength : float = 0.35	
@export var shake_fade : float = 2.5

var rng = RandomNumberGenerator.new()

var shake_strength: float = 0.0

var offset : Vector3

@export var target : Node3D

func _ready() -> void:
	get_tree().get_first_node_in_group("player").player_damaged.connect(apply_shake)
	offset = global_position

func apply_shake(_damage):
	shake_strength = random_strength

func _process(delta: float) -> void:
	#if target:
		#global_position = offset + target.global_position
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		var r_offset = random_offset()
		h_offset = r_offset.x
		v_offset = r_offset.y

func random_offset() -> Vector2:
	return Vector2(
		rng.randf_range(-shake_strength, shake_strength), # x
		rng.randf_range(-shake_strength, shake_strength)) # y
