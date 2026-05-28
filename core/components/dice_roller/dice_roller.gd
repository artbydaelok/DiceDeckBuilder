extends Node
class_name DiceRoller

## DiceRoller
##
## Handles the roll tween animation and face tracking for a dice mesh.
## Add as a child of the Player (or any node that needs rolling dice logic).
## Assign pivot and mesh in the inspector.
##
## Usage:
##   await dice_roller.roll(Vector3.FORWARD)
##   var top_face = dice_roller.faces["top"]

## The pivot node used as the rotation anchor during a roll.
@export var pivot: Node3D
## The dice mesh node being rotated.
@export var mesh: MeshInstance3D

@export var cube_size: float = 2.0
@export var speed: float = 4.0

## Current face mapping. Keys: "top", "bottom", "left", "right", "front", "back".
## Values: face number (1–6).
var faces: Dictionary = {
	"top":    2,
	"bottom": 5,
	"left":   6,
	"right":  1,
	"front":  3,
	"back":   4,
}

signal roll_completed


## Animate a roll in the given direction and update face tracking.
## Awaitable — caller resumes after the tween finishes.
func roll(dir: Vector3) -> void:
	# Step 1: Offset the pivot to the rolling edge.
	pivot.translate(dir * cube_size / 2)
	mesh.global_translate(-dir * cube_size / 2)

	# Step 2: Tween the rotation.
	var axis = dir.cross(Vector3.DOWN)
	var tween = create_tween()
	tween.tween_property(pivot, "transform",
		pivot.transform.rotated_local(axis, PI / 2), 1.0 / speed)
	await tween.finished

	# Update face tracking before finalising position.
	_update_faces(dir)

	# Step 3: Finalise position and reset pivot.
	var b = mesh.global_transform.basis
	pivot.transform = Transform3D.IDENTITY
	mesh.position = Vector3(0, cube_size / 2.0, 0)
	mesh.global_transform.basis = b

	roll_completed.emit()


func _update_faces(dir: Vector3) -> void:
	match dir:
		Vector3.FORWARD:
			var temp = faces.top
			faces.top = faces.back
			faces.back = faces.bottom
			faces.bottom = faces.front
			faces.front = temp
		Vector3.BACK:
			var temp = faces.top
			faces.top = faces.front
			faces.front = faces.bottom
			faces.bottom = faces.back
			faces.back = temp
		Vector3.LEFT:
			var temp = faces.top
			faces.top = faces.right
			faces.right = faces.bottom
			faces.bottom = faces.left
			faces.left = temp
		Vector3.RIGHT:
			var temp = faces.top
			faces.top = faces.left
			faces.left = faces.bottom
			faces.bottom = faces.right
			faces.right = temp
