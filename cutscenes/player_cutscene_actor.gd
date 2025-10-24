@tool
extends Node3D

enum ROLL_DIRECTION {
	NONE,
	FORWARD,
	LEFT,
	RIGHT,
	BACK
}

var rolling := false
var cube_size := 2.0
var speed := 4.0

@export var forced_dice_rotation : Vector3 = Vector3.ZERO:
	set(value):
		forced_dice_rotation = value
		dice_mesh.rotation = forced_dice_rotation
	get:
		return forced_dice_rotation

@export var pivot: Node3D 
@export var dice_mesh: MeshInstance3D 
@export_category("Dice Animations")
@export_subgroup("Dice Falling")
# Free Falling Animation
@export var free_falling := false
@export var falling_rotation_velocity: Vector3
@export_subgroup("Dice Movement")
@export var current_direction : ROLL_DIRECTION = ROLL_DIRECTION.NONE :
	set(value):
		current_direction = value
		var forward = Vector3.FORWARD
		match current_direction:
			ROLL_DIRECTION.FORWARD:
				roll(forward)
			ROLL_DIRECTION.BACK:
				roll(-forward)
			ROLL_DIRECTION.RIGHT:
				roll(forward.cross(Vector3.UP))
			ROLL_DIRECTION.LEFT:
				roll(-forward.cross(Vector3.UP))
	get:
		return current_direction
@export_tool_button("Reset Root Position") var reset_root_position_action = reset_position
@export_tool_button("Reset Dice Rotation") var reset_dice_rotation_action = reset_dice_rotation


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var forward = Vector3.FORWARD
	match current_direction:
		ROLL_DIRECTION.FORWARD:
			roll(forward)
		ROLL_DIRECTION.BACK:
			roll(-forward)
		ROLL_DIRECTION.RIGHT:
			roll(forward.cross(Vector3.UP))
		ROLL_DIRECTION.LEFT:
			roll(-forward.cross(Vector3.UP))
			
	if free_falling:
		dice_mesh.rotation += falling_rotation_velocity * delta
		

func reset_position():
	global_position = Vector3.ZERO
	rotation = Vector3.ZERO
	
func reset_dice_rotation():
	dice_mesh.rotation = Vector3.ZERO

func roll(dir):
	# Do nothing if we're currently rolling.
	if rolling:
		return
	
	rolling = true
	
	# Step 1: Offset the pivot.
	pivot.translate(dir * cube_size / 2)
	dice_mesh.global_translate(-dir * cube_size / 2)

	# Step 2: Animate the rotation.
	var axis = dir.cross(Vector3.DOWN)
	var tween = create_tween()
	tween.tween_property(pivot, "transform",
			pivot.transform.rotated_local(axis, PI/2), 1 / speed)
	await tween.finished

	# Step 3: Finalize the movement and reset the offset.
	transform.origin += dir * cube_size
	var b = dice_mesh.global_transform.basis
	pivot.transform = Transform3D.IDENTITY
	dice_mesh.position = Vector3(0, cube_size / 2, 0)
	dice_mesh.global_transform.basis = b
	rolling = false
