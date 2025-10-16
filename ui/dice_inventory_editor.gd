extends Control

@onready var item_list: VBoxContainer = %ItemList
const ITEM_DISPLAY = preload("uid://cdx4ewvsowtj3")

func _ready() -> void:
	_initialize()

func _initialize():
	var card_system = get_tree().get_first_node_in_group("card_system")
	var all_cards : Array[Card] = []
	all_cards.append_array(card_system.deck)
	all_cards.append_array(card_system.hand)
	for card in all_cards:
		_populate(card)
		
func _populate(card_data : Card):
	var item_display = ITEM_DISPLAY.instantiate()
	item_list.add_child(item_display)
	item_display.setup(card_data)

	#TODO: Populate the dice sides sprites on initialize

func _on_button_pressed() -> void:
	queue_free()
