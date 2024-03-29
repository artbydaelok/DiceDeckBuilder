extends Node

signal dice_moved(number: int)

func _ready():
	dice_moved.connect(on_dice_moved)

func on_dice_moved(number: int):
	print(number)
