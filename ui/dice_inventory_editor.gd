extends Control

@onready var item_list: VBoxContainer = %ItemList
const ITEM_DISPLAY = preload("uid://cdx4ewvsowtj3")

func _ready() -> void:
	_initialize()

func _initialize():
	var card_system = get_tree().get_first_node_in_group("card_system")
	for child in card_system.deck:
		_populate()
		
func _populate():
	var _item_display = ITEM_DISPLAY.instantiate()
	item_list.add_child(_item_display)
