extends CharacterBody3D
class_name Player

@onready var pivot = $Pivot
@onready var mesh = $Pivot/MeshInstance3D

# Grid Mesh Variables
@onready var grid_mesh: MeshInstance3D = $GridMesh
var grid_offset_start = 0.125
var grid_offset_amount = 0.25

@onready var side_one = $Pivot/MeshInstance3D/SideOne
@onready var side_two = $Pivot/MeshInstance3D/SideTwo
@onready var side_three = $Pivot/MeshInstance3D/SideThree
@onready var side_four = $Pivot/MeshInstance3D/SideFour
@onready var side_five = $Pivot/MeshInstance3D/SideFive
@onready var side_six = $Pivot/MeshInstance3D/SideSix

@onready var sides = [side_one, side_two, side_three, side_four, side_five, side_six]
enum SIDES_STATE {ONE, TWO, THREE, FOUR, FIVE, SIX}
var up_side = SIDES_STATE.TWO

@onready var commit_lock_timer: Timer = $CommitLockTimer
var commit_lock = false

var cube_size = 2.0
var speed = 4.0
var rolling = false

var x_grid_pos = 0
var y_grid_pos = 0

var disabled_pos = []

var grid_pos : Vector2

signal player_moved(direction : Vector2)
signal roll_finished()

# Health Variables
var health : int = 100
var is_dead : bool = false
var invulnerable : bool = false
var input_disabled : bool = false

signal player_damaged(damage_amount : float)
signal player_healed(heal_amount : float)
signal player_health_updated(new_health : float)
signal player_died

# Energy Variables
var energy : int = 6
signal energy_spent(amount : int)
signal energy_gained(amount : int)
signal insufficient_energy

@onready var shape_cast: ShapeCast3D = %ShapeCast


# Called when the node enters the scene tree for the first time.
func _ready():
	grid_pos = Vector2(x_grid_pos, y_grid_pos)
	player_health_updated.emit(health)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	GameEvents.cutscene_started.connect(_on_cutscene_started)
	GameEvents.cutscene_ended.connect(_on_cutscene_ended)
	GameEvents.menu_entered.connect(_on_menu_entered)
	GameEvents.menu_exited.connect(_on_menu_exited)
	
	if GameEvents.is_checkpoint_transfer:
		global_position = GameEvents.current_checkpoint_data.spawn_point + Vector3(0, 0, 2)
		GameEvents.set_deferred("is_checkpoint_transfer", false)

func _on_dialogue_started(resource):
	_on_cutscene_started(true)
	
func _on_dialogue_ended(resource : DialogueResource):
	_on_cutscene_ended()

func _on_cutscene_started(_input_disabled: bool):
	if _input_disabled:
		_disable_input()
	
func _on_cutscene_ended():
	if GameEvents.is_scene_transitioning: return
	await get_tree().create_timer(0.35).timeout
	_enable_input()

func _on_menu_entered():
	_disable_input()

func _on_menu_exited():
	_enable_input()

func _disable_input():
	input_disabled = true

func _enable_input():
	input_disabled = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	handle_input()

func handle_input():
	#if input_disabled: 
		#return
	var forward = Vector3.FORWARD
	if Input.is_action_pressed("move_forward"):
		roll(forward)
	if Input.is_action_pressed("move_backward"):
		roll(-forward)
	if Input.is_action_pressed("move_right"):
		roll(forward.cross(Vector3.UP))
	if Input.is_action_pressed("move_left"):
		roll(-forward.cross(Vector3.UP))

func update_side_icon(side : int, new_icon : Texture2D):
	match side:
		1:
			side_one.get_child(0).set_sprite(new_icon)
		2:
			side_two.get_child(0).set_sprite(new_icon)
		3:
			side_three.get_child(0).set_sprite(new_icon)
		4:
			side_four.get_child(0).set_sprite(new_icon)
		5:
			side_five.get_child(0).set_sprite(new_icon)
		6:
			side_six.get_child(0).set_sprite(new_icon)

func roll(dir):
	# Do nothing if we're currently rolling.
	if rolling or commit_lock or is_dead or input_disabled:
		return

	var test_dir = grid_pos + Vector2(dir.x, dir.z)

	## CHECK FOR COLLISION
	var collision_test_pos = dir * cube_size
	var initial_target_pos = shape_cast.target_position
	shape_cast.target_position = collision_test_pos
	shape_cast.force_shapecast_update()
	
	if shape_cast.is_colliding():
		shape_cast.target_position = initial_target_pos
		return
	
	
	
	rolling = true
	
	
	player_moved.emit(dir)
			
	# Step 1: Offset the pivot.
	pivot.translate(dir * cube_size / 2)
	mesh.global_translate(-dir * cube_size / 2)

	# Step 2: Animate the rotation.
	var axis = dir.cross(Vector3.DOWN)
	var tween = create_tween()
	# TODO: Use this same tween to smoothly tween the position of the player collision box from start position to end position.
	tween.tween_property(pivot, "transform",
			pivot.transform.rotated_local(axis, PI/2), 1 / speed)
	await tween.finished

	# Step 3: Finalize the movement and reset the offset.
	transform.origin += dir * cube_size
	var b = mesh.global_transform.basis
	pivot.transform = Transform3D.IDENTITY
	mesh.position = Vector3(0, cube_size / 2, 0)
	mesh.global_transform.basis = b
	rolling = false
	
	shape_cast.target_position = initial_target_pos
	
	x_grid_pos += dir.x
	y_grid_pos += dir.z
	grid_pos = Vector2(x_grid_pos, y_grid_pos)
	
	detect_side_up()
	$MoveSFX.play()
	
	roll_finished.emit()
	
	energy += 1
	energy = clamp(energy, 0, 6)
	energy_gained.emit(1)
	
	# This line offsets the grid UV so that it gives the illusion the player is moving with it.
	var _uv_offset = grid_mesh.mesh.surface_get_material(0).get_shader_parameter("uv1_offset")
	_uv_offset.x += grid_offset_amount
	grid_mesh.mesh.surface_get_material(0).set_shader_parameter("uv1_offset", _uv_offset)
	
	# This is a check for player death after a roll is finished
	if is_dead: 
		$DeathAnimation.play("death")

func add_blocked_pos(blocked_pos: Vector2):
	disabled_pos.append(blocked_pos)
	print("Adding " + str(blocked_pos))
	
func remove_blocked_pos(blocked_pos: Vector2):
	disabled_pos.erase(blocked_pos)
	print("Removing " + str(blocked_pos))

func detect_side_up():
	for s in sides:
		var s_pos = s.global_position
		if s_pos.y == 2:
			match s:
				side_one:
					up_side = SIDES_STATE.ONE
				side_two:
					up_side = SIDES_STATE.TWO
				side_three:
					up_side = SIDES_STATE.THREE
				side_four:
					up_side = SIDES_STATE.FOUR
				side_five:
					up_side = SIDES_STATE.FIVE
				side_six:
					up_side = SIDES_STATE.SIX
			
			# Send the signal to Game Events
			GameEvents.emit_signal("dice_moved", up_side + 1)

func heal_player(amount : float):
	health += amount
	health = clampf(health, 0, 100)
	player_healed.emit(amount)
	player_health_updated.emit(health)

func apply_damage(amount : float):
	if invulnerable: return
	invulnerable = true
	health -= amount
	health = clampf(health, 0, 100)
	player_damaged.emit(amount)
	player_health_updated.emit(health)
	
	$HurtSFX.play()
	
	if health == 0:
		## CHANGING SCENE TO RESTART LEVEL/MAIN MENU IS BEING TAKEN CARE OF IN THE HEALTH BAR SCRIPT ##
		is_dead = true
		player_died.emit()
		if not rolling:
			$DeathAnimation.play("death")
	
	await get_tree().create_timer(1.0).timeout
	
	invulnerable = false
	
func begin_attack_commit(commit_time : float):
	commit_lock_timer.wait_time = commit_time
	commit_lock = true
	commit_lock_timer.start()

func _on_commit_lock_timer_timeout() -> void:
	commit_lock = false
