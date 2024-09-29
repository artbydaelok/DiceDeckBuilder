extends CharacterBody3D
class_name Player

@onready var pivot = $Pivot
@onready var mesh = $Pivot/MeshInstance3D

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

var grid_pos : Vector2


# Health Variables
var health : int = 100
signal player_damaged(damage_amount : float)
signal player_healed(heal_amount : float)
signal player_health_updated(new_health : float)

# Called when the node enters the scene tree for the first time.
func _ready():
	grid_pos = Vector2(x_grid_pos, y_grid_pos)
	player_health_updated.emit(health)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
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
	if rolling or commit_lock:
		return
	rolling = true

	var test_dir = grid_pos + Vector2(dir.x, dir.z)

	if abs(test_dir.x) > 2 or abs(test_dir.y) > 2: 
		rolling = false
		return
		
	# Step 1: Offset the pivot.
	pivot.translate(dir * cube_size / 2)
	mesh.global_translate(-dir * cube_size / 2)

	# Step 2: Animate the rotation.
	var axis = dir.cross(Vector3.DOWN)
	var tween = create_tween()
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
	
	
	x_grid_pos += dir.x
	y_grid_pos += dir.z
	grid_pos = Vector2(x_grid_pos, y_grid_pos)
	
	detect_side_up()

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
	health -= amount
	health = clampf(health, 0, 100)
	player_damaged.emit(amount)
	player_health_updated.emit(health)
	
	if health == 0:
		print("Player Died")
	
func begin_attack_commit(commit_time : float):
	commit_lock_timer.wait_time = commit_time
	commit_lock = true
	commit_lock_timer.start()

func _on_commit_lock_timer_timeout() -> void:
	commit_lock = false
