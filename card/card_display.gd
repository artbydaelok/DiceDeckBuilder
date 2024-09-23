extends Control

var current_card_data : Card
@onready var card_hover_animation: AnimationPlayer = $CardHoverAnimation

var hovered = false

@onready var card_name: Label = %CardName
@onready var card_art: TextureRect = %CardArt
@onready var description_label: Label = %DescriptionLabel

func setup(card_data):
	current_card_data = card_data
	card_name.text = current_card_data.card_name
	description_label.text = current_card_data.card_description
	card_art.texture = current_card_data.card_artwork

func hover():
	hovered = true
	card_hover_animation.play("on_hover")

func undo_hover():
	if hovered == true:
		hovered = false
		card_hover_animation.play_backwards("on_hover")
