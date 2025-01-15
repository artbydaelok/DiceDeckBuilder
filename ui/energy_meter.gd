extends HBoxContainer

@export var player : Node

func _ready() -> void:
	player.energy_spent.connect(update_energy_display)
	player.energy_gained.connect(update_energy_display)

func update_energy_display(amount):
	print(player.energy)
	for child in get_children():
		if child.get_index() >= player.energy:
			child.get_child(0).visible = false
		else:
			child.get_child(0).visible = true
