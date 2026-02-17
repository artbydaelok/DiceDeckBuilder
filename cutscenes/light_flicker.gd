@tool
extends Light3D


@export_category("Flicker Settings")
@export var can_flicker : bool = false
@export_subgroup("Flicker Interval Randomness")
@export var min_interval : float = 0.1
@export var max_interval : float = 0.5
@export_subgroup("Flicker Strength Randomness")
@export var min_energy : float = 9.5
@export var max_energy : float = 12.5
@export_tool_button("Start Flicker") var start_flicker_action = start_flicker

func _ready() -> void:
	can_flicker = true
	start_flicker()

func start_flicker():
	if can_flicker:
		var wait_time = randf_range(min_interval, max_interval)
		light_energy = randf_range(min_energy, max_energy)
		await get_tree().create_timer(wait_time).timeout
		start_flicker()
