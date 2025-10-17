extends Control

@onready var item_list: VBoxContainer = %ItemList

const ITEM_DISPLAY = preload("uid://cdx4ewvsowtj3")

var current_side : int = -1

var card_system : Node

func _ready() -> void:
	_initialize()

func _initialize():
	card_system = get_tree().get_first_node_in_group("card_system")
	GameEvents.side_editing_started.connect(_on_side_editing_started)
	var all_cards : Array[Card] = []
	all_cards.append_array(card_system.deck)
	all_cards.append_array(card_system.hand)
	for card in all_cards:
		_populate(card)
		
func _populate(card_data : Card):
	var item_display = ITEM_DISPLAY.instantiate()
	item_list.add_child(item_display)
	item_display.setup(card_data)
	item_display.pressed.connect(_on_item_display_pressed)
	
	#TODO: Populate the dice sides sprites on initialize

func _on_button_pressed() -> void:
	#TODO: Allow player to regain control here.
	queue_free()

func _on_side_editing_started(_side : int):
	current_side = _side

func _on_item_display_pressed(card_data: Card):
	if current_side != -1:
		GameEvents.side_updated_item.emit(current_side, card_data)
