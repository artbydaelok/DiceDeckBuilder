extends Node3D
class_name Vehicle

## Base class for all vehicles.
## Carries the player by applying the vehicle's own frame delta directly
## to the player's global_position — no physics velocity inheritance needed.

const CELL_SIZE := 2.0

## Emitted when a player boards this vehicle.
signal player_boarded(player: Player)
## Emitted when a player leaves this vehicle.
signal player_disembarked(player: Player)

## Whether the vehicle is currently accepting new boarders.
var is_boardable: bool = false
## The player currently on this vehicle, or null.
var current_player: Player = null

var _last_position: Vector3


# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_last_position = global_position
	var area := _get_boarding_area()
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	vehicle_ready()


func _process(_delta: float) -> void:
	vehicle_process(_delta)
	_carry_player()
	_last_position = global_position


# ── Player carrying ──────────────────────────────────────────────────────────

func _carry_player() -> void:
	if current_player == null:
		return
	var delta_pos := global_position - _last_position
	if delta_pos != Vector3.ZERO:
		current_player.global_position += delta_pos


# ── Boarding ─────────────────────────────────────────────────────────────────

func _on_body_entered(body: Node3D) -> void:
	if not is_boardable: return
	if current_player != null: return
	if body is not Player: return
	_board(body as Player)


func _on_body_exited(body: Node3D) -> void:
	if body != current_player: return
	_disembark()


func _board(player: Player) -> void:
	current_player = player
	_snap_player_to_grid()
	on_player_boarded(player)
	player_boarded.emit(player)


func _disembark() -> void:
	var player := current_player
	current_player = null
	on_player_disembarked(player)
	player_disembarked.emit(player)


## Call this from an ability to board a specific player immediately,
## bypassing the Area3D (used by AbilityVehicle / skateboard).
func force_board(player: Player) -> void:
	current_player = player
	_snap_player_to_grid()
	on_player_boarded(player)
	player_boarded.emit(player)


func force_disembark() -> void:
	if current_player == null: return
	_disembark()


# ── Grid snap ────────────────────────────────────────────────────────────────

func _snap_player_to_grid() -> void:
	if current_player == null: return
	var pos := current_player.global_position
	pos.x = round(pos.x / CELL_SIZE) * CELL_SIZE
	pos.z = round(pos.z / CELL_SIZE) * CELL_SIZE
	current_player.global_position = pos


# ── Helpers ──────────────────────────────────────────────────────────────────

func _get_boarding_area() -> Area3D:
	for child in get_children():
		if child is Area3D:
			return child
	return null


# ── Overridable hooks ────────────────────────────────────────────────────────

func vehicle_ready() -> void: pass
func vehicle_process(delta: float) -> void: pass
func on_player_boarded(player: Player) -> void: pass
func on_player_disembarked(player: Player) -> void: pass
