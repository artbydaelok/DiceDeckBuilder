extends Control

@export var card_system : Node
@export var card_scene : PackedScene

@onready var deck_container: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/DeckContainer

var viewer_open : bool = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("view_deck") and not viewer_open:
		visible = true
		setup()
		viewer_open = true
	elif Input.is_action_just_pressed("view_deck") and viewer_open:
		visible = false
		viewer_open = false


func setup():
	# Refresh the UI
	for card in deck_container.get_children():
		card.queue_free()
	
	# Add all the cards.
	for card in card_system.hand:
		var new_card = card_scene.instantiate()
		deck_container.add_child(new_card)
		new_card.setup(card)
		
	for card in card_system.deck:
		var new_card = card_scene.instantiate()
		deck_container.add_child(new_card)
		new_card.setup(card)
	
	for card in card_system.discard_pile:
		var new_card = card_scene.instantiate()
		deck_container.add_child(new_card)
		new_card.setup(card)
