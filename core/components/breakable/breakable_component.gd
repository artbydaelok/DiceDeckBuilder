extends Node3D

## BreakableComponent
##
## Drop this as a child of any object you want to be breakable by the axe.
## The component scene should have a StaticBody3D and an Area3D as children.
##
## The parent object connects to the [broke] signal to handle its own
## death behaviour (hide mesh, play particles, spawn drops, etc.)
##
## Node structure expected inside the component scene:
##   BreakableComponent  <-- this script
##   ├── StaticBody3D    <-- blocks the player; disabled on break
##   │   └── CollisionShape3D
##   └── Area3D          <-- detected by the axe projectile
##       └── CollisionShape3D

## Emitted when health reaches zero. Connect this in the parent to trigger
## visuals, particles, drops, etc.
signal broke

## How many axe hits it takes to break this object.
@export var health: int = 1

## Unique ID for this object within its level. Used to persist broken state.
## Set this in the editor — must be unique per level (e.g. "log_01", "barrel_entrance").
## Leave blank to skip state persistence for this object.
@export var object_id: String = ""

@onready var static_body: StaticBody3D = $StaticBody3D
@onready var detection_area: Area3D = $AxeDetectionArea

var is_broken: bool = false


func _ready() -> void:
	if object_id == "":
		return
	var level_id := get_tree().current_scene.name
	if SaveSystem.get_level_flag(level_id, object_id, false):
		# Already broken in a previous session — break silently without emitting
		_break_silent()


## Called by the axe projectile (axe_projectile.gd) when it enters the Area3D.
## Matches the calling convention: Callable(area.get_parent(), "axe_hit")
func axe_hit() -> void:
	take_damage(1)


## Apply damage directly — useful if you want other things (fire, explosions)
## to also break this object.
func take_damage(amount: int = 1) -> void:
	if is_broken:
		return
	health -= amount
	if health <= 0:
		_break()


func _break() -> void:
	if is_broken:
		return
	is_broken = true
	_disable_collisions()

	# Persist the broken state
	if object_id != "":
		var level_id := get_tree().current_scene.name
		SaveSystem.set_level_flag(level_id, object_id, true)
		SaveSystem.save_player_data()

	emit_signal("broke")


## Break without emitting the signal — used on _ready to restore already-broken state.
## The parent should hide the mesh on its own _ready if needed, or connect to broke
## and handle visibility there.
func _break_silent() -> void:
	if is_broken:
		return
	is_broken = true
	_disable_collisions()


func _disable_collisions() -> void:
	# Disable all collision shapes on the static body so the player can walk through.
	for child in static_body.get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)

	# Disable the detection area so the axe can't trigger it again.
	for child in detection_area.get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)
