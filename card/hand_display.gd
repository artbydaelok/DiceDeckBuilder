extends HBoxContainer
class_name HandDisplay

var card_slots = []

var last_index_selected : int

# Called when the node enters the scene tree for the first time.
func _ready():
	GameEvents.dice_moved.connect(on_dice_moved)
	card_slots = get_children()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_dice_moved(_index):
	var selected_card = card_slots[_index - 1]
	selected_card.hover()
	if last_index_selected != -1:
		card_slots[last_index_selected].undo_hover()
	last_index_selected = _index - 1

# This function updates the data of a card in the hand.
func update_index(index, card_data):
	card_slots[index].setup(card_data)

func on_played_card(index: int):
	get_child(index).card_selected()
