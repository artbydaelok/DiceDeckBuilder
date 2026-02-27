extends Camera3D
class_name GameCamera

@export var random_strength : float = 0.35	
@export var shake_fade : float = 2.5

var rng = RandomNumberGenerator.new()

var shake_strength: float = 0.0

var offset : Vector3

var player : Player

@export var target : Node3D
@export var follow_target : bool = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	player.player_damaged.connect(apply_shake)
	
	update_target_offset()

func update_target_offset(new_offset = null):
	if target != null:
		print("Current Camera position is: " + str(global_position))
		print("Current Target position is: " + str(target.global_position))
		if new_offset == null:
			offset = global_position - target.global_position
		else:
			offset = new_offset
		print("New camera offset: " + str(offset))

func stop_following_target():
	follow_target = false

func start_following_target(target = null):
	if target != null:
		set_target(target)
	follow_target = true

func set_target(new_target : Node3D):
	target = new_target

func apply_shake(_damage):
	shake_strength = random_strength

func _process(delta: float) -> void:
	if target and follow_target:
		global_position = offset + target.global_position
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		var r_offset = random_offset()
		h_offset = r_offset.x
		v_offset = r_offset.y

func random_offset() -> Vector2:
	return Vector2(
		rng.randf_range(-shake_strength, shake_strength), # x
		rng.randf_range(-shake_strength, shake_strength)) # y
		
func relocate_to(node : Node3D, new_offset = null):
	var target_original_position 
	if target:
		target_original_position = target.global_position
	
	var tween : Tween = create_tween()
	stop_following_target()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", node.global_position, 0.15)
	tween.tween_property(self, "global_rotation", node.global_rotation, 0.15)
	
	await tween.finished
	
	#GameEvents.enable_player_input()
	if new_offset != null:
		update_target_offset(new_offset)
	else:
		update_target_offset(node.global_position - target_original_position)
	
	start_following_target()
