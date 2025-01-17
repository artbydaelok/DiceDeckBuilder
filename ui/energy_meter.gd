extends HBoxContainer

@export var player : Node
@export var insufficient_label : Label
@export var insufficient_timer: Timer

func _ready() -> void:
	player.energy_spent.connect(update_energy_display)
	player.energy_gained.connect(update_energy_display)
	player.insufficient_energy.connect(display_insufficient_energy)

func update_energy_display(amount):
	print(player.energy)
	for child in get_children():
		if child.get_index() >= player.energy:
			child.get_child(0).visible = false
		else:
			child.get_child(0).visible = true

func display_insufficient_energy():
	insufficient_label.visible = true
	insufficient_timer.start()
	await insufficient_timer.timeout
	insufficient_label.visible = false
