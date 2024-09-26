extends Control

@onready var result_label: Label = %ResultLabel

func setup(player_win: bool = false):
	if player_win:
		result_label.text = "Jeez, you really murdered him"
