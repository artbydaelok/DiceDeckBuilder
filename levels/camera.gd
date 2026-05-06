extends Camera3D
class_name GameCamera

const CAMERA_ANGLE_HOLDER = preload("uid://n8h15ynu2crs")
var starting_cam_holder : Marker3D

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
	
	create_starting_angle_holder()
	
	if GameEvents.current_checkpoint_data != null:
		global_position = GameEvents.current_checkpoint_data.spawn_point + GameEvents.current_checkpoint_data.camera_offset
	
	update_target_offset()

func create_starting_angle_holder():
	starting_cam_holder = CAMERA_ANGLE_HOLDER.instantiate()
	get_tree().get_first_node_in_group("player").add_child(starting_cam_holder)
	starting_cam_holder.global_transform = global_transform
	starting_cam_holder.set_player()
	

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
	if player.rolling:
		await player.roll_finished

	stop_following_target()

	var duration := 0.15
	var start_pos := global_position
	var start_rot := global_basis.get_rotation_quaternion()

	var tween := create_tween()

	tween.tween_method(
		func(t: float):
			if not is_instance_valid(node):
				return

			# Re-read target every frame
			var target_pos := node.global_position
			var target_rot := node.global_basis.get_rotation_quaternion()

			global_position = start_pos.lerp(target_pos, t)
			global_basis = Basis(start_rot.slerp(target_rot, t)),
		0.0,
		1.0,
		duration
	)

	await tween.finished

	update_target_offset()
	#if new_offset != null:
		#update_target_offset(new_offset)
	#else:
		#update_target_offset(node.global_position - target_original_position)
	
	start_following_target()
