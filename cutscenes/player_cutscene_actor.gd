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

# Internal state for borrow/release
var _borrowed_pivot: Node3D = null
var _original_pivot_parent: Node = null
var _original_actor_pivot: Node3D = null
var _original_actor_mesh: MeshInstance3D = null

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


## Reparents the player's Pivot (with its mesh, icons, and rotation intact) onto
## this actor so the cutscene uses the real dice visuals.
## Call this at the start of any cutscene that needs to show the player's dice.
func borrow_from_player() -> void:
	if Engine.is_editor_hint():
		return
	var player: Node3D = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("PlayerCutsceneActor: no node in group 'player' found.")
		return

	var player_pivot: Node3D = player.get_node("Pivot")
	var player_mesh: MeshInstance3D = player.get_node("Pivot/MeshInstance3D")

	# Remember originals so we can restore later
	_borrowed_pivot = player_pivot
	_original_pivot_parent = player_pivot.get_parent()
	_original_actor_pivot = pivot
	_original_actor_mesh = dice_mesh

	# Hide the actor's own placeholder mesh
	if pivot:
		pivot.visible = false

	# Move the player's pivot here, keeping its world transform
	player_pivot.reparent(self, true)

	# Point the roll logic at the borrowed nodes
	pivot = player_pivot
	dice_mesh = player_mesh


## Returns the borrowed pivot back to the player and restores the actor's
## own placeholder. Call this when the cutscene ends.
func release_to_player() -> void:
	if _borrowed_pivot == null:
		return

	# Return pivot to player, keeping world transform
	_borrowed_pivot.reparent(_original_pivot_parent, true)

	# Restore the pivot's local transform to the neutral state the player expects
	_borrowed_pivot.transform = Transform3D.IDENTITY
	_borrowed_pivot.get_node("MeshInstance3D").position = Vector3(0, 1.0, 0)

	# Restore actor's own nodes
	pivot = _original_actor_pivot
	dice_mesh = _original_actor_mesh
	if pivot:
		pivot.visible = true

	_borrowed_pivot = null
	_original_pivot_parent = null


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
		dice_mesh.global_rotate(Vector3.RIGHT,   falling_rotation_velocity.x * delta)
		dice_mesh.global_rotate(Vector3.UP,      falling_rotation_velocity.y * delta)
		dice_mesh.global_rotate(Vector3.FORWARD, falling_rotation_velocity.z * delta)
		

func pivot_to_center():
	var offset = dice_mesh.position
	dice_mesh.position = Vector3.ZERO
	pivot.position = offset
	

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
