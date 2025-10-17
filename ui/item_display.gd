extends PanelContainer

@onready var item_icon: TextureRect = $MarginContainer/HBoxContainer/ItemIcon
@onready var item_label: Label = $MarginContainer/HBoxContainer/ItemLabel
@onready var button: Button = $Button

signal pressed(card : Card)

var card_data : Card

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)

func setup(_card_data: Card):
	card_data = _card_data
	item_icon.texture = card_data.card_artwork
	item_label.text = card_data.card_name

func _on_button_pressed():
	pressed.emit(card_data)

#TODO: Make this a button that assigns its card data to the active side.
# Possibly use a signal that emits when pressed that also sends that data. 
# Connect it when this is created in the UI element Script.
