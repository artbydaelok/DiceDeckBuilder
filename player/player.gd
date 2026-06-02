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

# Face tracking and roll animation — owned by DiceRoller
@onready var dice_roller: DiceRoller = $DiceRoller

# Passthrough so external scripts (e.g. ability_sides_display) can still use player.faces
var faces: Dictionary:
	get: return dice_roller.faces

@onready var commit_lock_timer: Timer = $CommitLockTimer
var commit_lock = false

var cube_size = 2.0
var speed = 4.0
var rolling = false

var x_grid_pos = 0
var y_grid_pos = 0


var grid_pos : Vector2

signal player_moved(direction : Vector2)
signal roll_finished()

var input_disabled : bool = false

## Flip ability — granted by story event, not an item.
var has_flip: bool = false
const FLIP_ENERGY_COST := 1

# Health — handled by HealthComponent child node
@onready var health_component: HealthComponent = $HealthComponent

# Passthrough signals so external scripts don't need to change
signal player_damaged(damage_amount : float)
signal player_healed(heal_amount : float)
signal player_health_updated(new_health : float)
signal player_died

# Energy — handled by EnergyComponent child node
@onready var energy_component: EnergyComponent = $EnergyComponent

# Passthrough signals so external scripts (UI etc.) don't need to change
signal energy_spent(amount: int)
signal energy_gained(amount: int)
signal insufficient_energy

@onready var shape_cast: ShapeCast3D = %ShapeCast

@onready var player_trigger_collision: CollisionShape3D = %PlayerTriggerCollision


# Called when the node enters the scene tree for the first time.
func _ready():
	grid_pos = Vector2(x_grid_pos, y_grid_pos)

	# Wire HealthComponent signals — keep SFX/particles/animation here in the player
	health_component.damaged.connect(_on_damaged)
	health_component.healed.connect(_on_healed)
	health_component.health_updated.connect(_on_health_updated)
	health_component.died.connect(_on_died)

	# Wire EnergyComponent passthrough signals
	energy_component.spent.connect(energy_spent.emit)
	energy_component.gained.connect(energy_gained.emit)
	energy_component.insufficient.connect(insufficient_energy.emit)

	GameEvents.cutscene_started.connect(_on_cutscene_started)
	GameEvents.cutscene_ended.connect(_on_cutscene_ended)
	GameEvents.menu_entered.connect(_on_menu_entered)
	GameEvents.menu_exited.connect(_on_menu_exited)

	if GameEvents.is_checkpoint_transfer:
		global_position = GameEvents.current_checkpoint_data.spawn_point + Vector3(0, 0, 2)
		GameEvents.set_deferred("is_checkpoint_transfer", false)

	has_flip = true

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
	if GameEvents.is_in_menu: return
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
	if Input.is_action_just_pressed("flip") and has_flip:
		_perform_flip()
		
	#if Input.is_key_pressed(KEY_SPACE):
		#leap()

func get_side_texture(side : int):
	return sides[side - 1].get_child(0).texture

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
	DiceState.update_icon(side, new_icon)

func leap():
	# Do nothing if we're currently rolling.
	if rolling or commit_lock or health_component.is_dead or input_disabled:
		return
	
	var dir := Vector3.FORWARD
	
	## CHECK FOR COLLISION
	var collision_test_pos = dir * cube_size
	var initial_target_pos = shape_cast.target_position
	shape_cast.target_position = collision_test_pos
	shape_cast.force_shapecast_update()
	
	# This prevents the player from using items while not standing still, 
	# and to allow for triggers to work before player can move out of them
	_disable_input()

	rolling = true

	player_moved.emit(dir)
	
	var tween_position := create_tween()
	#var tween_rotation := create_tween()
	
	# Step 1: Offset the pivot.
	pivot.translate(Vector3(0, 1, 0))
	mesh.global_translate(Vector3(0, -1, 0))
	
	var axis = dir.cross(Vector3.DOWN)
	
	var step_1 = pivot.transform.rotated_local(axis, PI/4).translated(Vector3(0, 4, -2))
	var step_2 = pivot.transform.rotated_local(axis, PI/2).translated(Vector3(0, 0, -4))
	
	# TODO: Use this same tween to smoothly tween the position of the player collision box from start position to end position.
	#tween_rotation.tween_property(pivot, "rotation", )
	tween_position.tween_property(pivot, "transform", 
		step_1, 1/speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween_position.tween_property(pivot, "transform", 
		step_2, 1/speed).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween_position.finished
	
	#roll_finished.emit()
	
	
	# Step 3: Finalize the movement and reset the offset.
	transform.origin += dir * cube_size * 2.0
	var b = mesh.global_transform.basis
	pivot.transform = Transform3D.IDENTITY
	mesh.position = Vector3(0, cube_size / 2, 0)
	mesh.global_transform.basis = b
	
	await get_tree().create_timer(1).timeout
	rolling = false
	_enable_input()
	
func roll(dir):
	# Do nothing if we're currently rolling.
	if rolling or commit_lock or health_component.is_dead or input_disabled:
		return
		
	## CHECK FOR COLLISION
	var collision_test_pos = dir * cube_size
	var initial_target_pos = shape_cast.target_position
	shape_cast.target_position = collision_test_pos
	shape_cast.force_shapecast_update()
	
	if shape_cast.is_colliding():
		shape_cast.target_position = initial_target_pos
		return
	
	# This prevents the player from using items while not standing still,
	# and to allow for triggers to work before player can move out of them
	_disable_input()

	rolling = true
	player_moved.emit(dir)

	# Delegate animation + face tracking to DiceRoller
	await dice_roller.roll(dir)

	# Move the CharacterBody3D after the tween
	transform.origin += dir * cube_size
	shape_cast.target_position = initial_target_pos

	x_grid_pos += dir.x
	y_grid_pos += dir.z
	grid_pos = Vector2(x_grid_pos, y_grid_pos)

	detect_side_up()
	DiceState.update_after_roll(mesh.global_transform.basis, dice_roller.faces)
	$MoveSFX.play()
	
	roll_finished.emit()
	
	energy_component.gain(1)
	
	
	
	await get_tree().process_frame
	
	rolling = false
	
	# This line offsets the grid UV so that it gives the illusion the player is moving with it.
	var _uv_offset = grid_mesh.mesh.surface_get_material(0).get_shader_parameter("uv1_offset")
	_uv_offset.x += grid_offset_amount
	grid_mesh.mesh.surface_get_material(0).set_shader_parameter("uv1_offset", _uv_offset)
	
	
	# This is a check for player death after a roll is finished
	if health_component.is_dead:
		$DeathAnimation.play("death")
	
	if not GameEvents.is_in_menu and not GameEvents.is_in_cutscene:
		_enable_input.call_deferred()

func detect_side_up() -> void:
	# Read directly from DiceRoller's face tracking — discrete logic, no float comparison.
	# faces["top"] is always correct after every roll and flip.
	var top_face: int = dice_roller.faces["top"]  # 1–6
	up_side = (top_face - 1) as SIDES_STATE       # ONE=0 … SIX=5
	GameEvents.emit_signal("dice_moved", top_face)

## Public API — called by enemies, traps, pickups, etc.
func heal_player(amount: float) -> void:
	health_component.heal(amount)

func apply_damage(amount: float) -> void:
	health_component.apply_damage(amount)

## HealthComponent signal handlers
func _on_damaged(amount: float) -> void:
	player_damaged.emit(amount)
	$HurtSFX.play()

func _on_healed(amount: float) -> void:
	player_healed.emit(amount)
	$HealSFX.play()
	$HealParticles.emitting = true

func _on_health_updated(new_health: float) -> void:
	player_health_updated.emit(new_health)

func _on_died() -> void:
	## CHANGING SCENE TO RESTART LEVEL/MAIN MENU IS BEING TAKEN CARE OF IN THE HEALTH BAR SCRIPT ##
	player_died.emit()
	if not rolling:
		$DeathAnimation.play("death")
	
func begin_attack_commit(commit_time : float):
	commit_lock_timer.wait_time = commit_time
	commit_lock = true
	commit_lock_timer.start()

func _on_commit_lock_timer_timeout() -> void:
	commit_lock = false


# ── Flip ability ──────────────────────────────────────────────────────────────

func _perform_flip() -> void:
	if rolling or commit_lock or health_component.is_dead or input_disabled:
		return
	if not energy_component.has_enough(FLIP_ENERGY_COST):
		energy_component.insufficient.emit()
		return

	rolling = true
	_disable_input()
	energy_component.spend(FLIP_ENERGY_COST)

	var origin_y := position.y

	# Jump up
	var t_up := create_tween()
	t_up.tween_property(self, "position:y", origin_y + cube_size, 0.2) \
		.set_ease(Tween.EASE_OUT)
	await t_up.finished

	# Spin the dice 180° at the peak
	await dice_roller.flip()

	# Land back down with a small bounce
	var t_down := create_tween()
	t_down.tween_property(self, "position:y", origin_y, 0.25) \
		.set_ease(Tween.EASE_IN)
	await t_down.finished

	detect_side_up()
	DiceState.update_after_roll(mesh.global_transform.basis, dice_roller.faces)

	rolling = false
	_enable_input()
