extends Control

var current_card_data : Card
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var hovered = false

@onready var card_name: Label = %CardName
@onready var card_art: TextureRect = %CardArt
@onready var description_label: Label = %DescriptionLabel
@onready var cost_label: Label = $PanelContainer/MarginContainer/PanelContainer/CostLabel

var disabled = false

func setup(card_data):
	current_card_data = card_data
	card_name.text = current_card_data.card_name
	description_label.text = current_card_data.card_description
	card_art.texture = current_card_data.card_artwork
	cost_label.text = str(current_card_data.cost)

func hover():
	if not disabled:
		hovered = true
		animation_player.play("on_hover")

func undo_hover():
	if not disabled:
		hovered = false
		animation_player.play_backwards("on_hover")

func card_selected():
	disabled = true
	animation_player.play("card_selected")
	await animation_player.animation_finished
	draw_card_animation()
	
func draw_card_animation():
	disabled = false
	animation_player.play("draw_card")
	await animation_player.animation_finished
	if hovered:
		animation_player.play("on_hover")
		
