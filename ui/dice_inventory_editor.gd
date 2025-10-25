extends Control

@onready var item_list: VBoxContainer = %ItemList
@onready var rotation_speed_slider: HSlider = %RotationSpeedSlider

const ITEM_DISPLAY = preload("uid://cdx4ewvsowtj3")

var current_side : int = -1

var card_system : Node

var rotation_increase_amount : float = 0.05
var default_rotation_speed : float = 0.5

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
	
	for i in range(card_system.hand.size()):
		GameEvents.side_updated_item.emit(i, card_system.hand[i])
		
#BKMRK: This is where the cards get spawned in and populated with data.
func _populate(card_data : Card):
	var item_display = ITEM_DISPLAY.instantiate()
	item_list.add_child(item_display)
	item_display.setup(card_data)
	item_display.pressed.connect(_on_item_display_pressed)
	

func _on_button_pressed() -> void:
	#TODO: Allow player to regain control here.
	queue_free()

func _on_side_editing_started(_side : int):
	current_side = _side

func _on_item_display_pressed(card_data: Card):
	if current_side != -1:
		GameEvents.side_updated_item.emit(current_side, card_data)
		card_system.set_slot_to_item(current_side, card_data)

	#FIXME: Player can currently assign one weapon to multiple sides. 
	#IDEA: As a design decision I think we should allow to give players the chance to put a maximum 2 of each item on their dice.


func _on_rotation_speed_slider_value_changed(value: float) -> void:
	GameEvents.dice_viewer_rotation_speed_updated.emit(value)


func _on_less_rotation_speed_button_pressed() -> void:
	var value = rotation_speed_slider.value - rotation_increase_amount
	rotation_speed_slider.value = value
	GameEvents.dice_viewer_rotation_speed_updated.emit(value)


func _on_more_rotation_speed_button_pressed() -> void:
	var value = rotation_speed_slider.value + rotation_increase_amount
	rotation_speed_slider.value = value
	GameEvents.dice_viewer_rotation_speed_updated.emit(value)


func _on_default_rotation_speed_button_pressed() -> void:
	rotation_speed_slider.value = default_rotation_speed
