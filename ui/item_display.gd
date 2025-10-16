extends PanelContainer

@onready var item_icon: TextureRect = $MarginContainer/HBoxContainer/ItemIcon
@onready var item_label: Label = $MarginContainer/HBoxContainer/ItemLabel

func setup(card_data: Card):
	item_icon.texture = card_data.card_artwork
	item_label.text = card_data.card_name

#TODO: Make this a button that assigns its card data to the active side.
# Possibly use a signal that emits when pressed that also sends that data. 
# Connect it when this is created in the UI element Script.
