extends CharacterBody3D

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
var up_side = SIDES_STATE.ONE

var cube_size = 2.0
var speed = 4.0
var rolling = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


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


func roll(dir):
	# Do nothing if we're currently rolling.
	if rolling:
		return
	rolling = true

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
	
	detect_side_up()

func detect_side_up():
	for s in sides:
		#print(s.name + " " + str(sides[0].global_translation))
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
