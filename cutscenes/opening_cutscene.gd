extends Node3D

const OPENING_CUSTCENE = preload("uid://mrq3y0iqiqdg")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vortex_enter_sequence()

func vortex_enter_sequence():
	DialogueManager.show_dialogue_balloon(OPENING_CUSTCENE, "enter_vortex")
