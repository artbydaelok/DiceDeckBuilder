extends HBoxContainer

@export var player : Node
@export var insufficient_label : Label
@export var insufficient_timer: Timer
@onready var insufficient_energy_sfx: AudioStreamPlayer = $InsufficientEnergySFX

func _ready() -> void:
	player.energy_spent.connect(update_energy_display)
	player.energy_gained.connect(update_energy_display)
	player.insufficient_energy.connect(display_insufficient_energy)

func update_energy_display(amount):
	print(player.energy)
	for child in get_children():
		if not child is Control: return
		if child.get_index() >= player.energy:
			child.get_child(0).visible = false
		else:
			child.get_child(0).visible = true

func display_insufficient_energy():
	insufficient_label.visible = true
	insufficient_timer.start()
	insufficient_energy_sfx.play()
	await insufficient_timer.timeout
	insufficient_label.visible = false
