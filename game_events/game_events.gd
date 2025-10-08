extends Node

signal dice_moved(number: int)
signal cutscene_started(disable_input : bool)
signal cutscene_ended

func _ready():
	dice_moved.connect(on_dice_moved)

func on_dice_moved(number: int):
	#print(number)
	pass
