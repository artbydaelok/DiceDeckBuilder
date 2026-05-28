extends Node
class_name EnergyComponent

## EnergyComponent
##
## Tracks the player's energy (action points spent on abilities and gained on rolls).
## Add as a child of the Player. CardSystem can reference it directly via export.
##
## Usage:
##   energy_component.gain(1)
##   if energy_component.has_enough(cost): energy_component.spend(cost)

@export var max_energy: int = 6

var energy: int

signal spent(amount: int)
signal gained(amount: int)
signal insufficient


func _ready() -> void:
	energy = max_energy


func has_enough(amount: int) -> bool:
	return energy >= amount


func spend(amount: int) -> void:
	if not has_enough(amount):
		insufficient.emit()
		return
	energy -= amount
	energy = clampi(energy, 0, max_energy)
	spent.emit(amount)


func gain(amount: int) -> void:
	energy += amount
	energy = clampi(energy, 0, max_energy)
	gained.emit(amount)
