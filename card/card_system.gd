extends Node

@export var hand : Array[Card]
@export var deck : Array[Card]
@export var discard_pile : Array[Card]

@export var hand_display : Control

@export var player : Player 

const CARD_DISPLAY = preload("res://card/card_display.tscn")

func _ready() -> void:
	# Test Draw At Start
	shuffle_deck()
	for i in range(6):
		print(i)
		draw_card(i)
		
func draw_card(index: int):
	# Move card from deck to hand.
	var card_to_draw = deck[0]
	hand.insert(index, card_to_draw)
	deck.remove_at(0)
	
	# Update the UI
	hand_display.update_index(index, card_to_draw)
	
	# Update Player's Icons
	player.update_side_icon(index + 1, hand[index].card_artwork)

func shuffle_deck():
	deck.shuffle()

func discard_card():
	pass

func draw_full_hand():
	pass
