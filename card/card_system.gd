extends Node

@export var hand : Array[Card]
@export var deck : Array[Card]
@export var discard_pile : Array[Card]

@export var hand_display : Control

@export var player : Player 

# Match the Ability ID.
const CARD_ABILITIES = {
	"arrow" : preload("res://abilities/arrow/bow_and_arrow.tscn"),
	"axe" : preload("res://abilities/axe_throw/axe_throw.tscn"),
	"balloon" : preload("res://abilities/balloon/balloon_pop.tscn"),
	"swipe" : preload("res://abilities/bear_swipe/bear_swipe.tscn"),
	"shotgun" : preload("res://abilities/shotgun/shotgun_blast.tscn"),
}

const CARD_DISPLAY = preload("res://card/card_display.tscn")

func _ready() -> void:
	# Test Draw At Start
	shuffle_deck()
	for i in range(6):
		print(i)
		draw_card(i)
		
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("use_ability"):
		play_ability(hand[player.up_side].ability_id)
		
func draw_card(index: int):
	# Move card from deck to hand.
	var card_to_draw = deck[0]
	hand.insert(index, card_to_draw)
	deck.remove_at(0)
	
	# Update the UI
	hand_display.update_index(index, card_to_draw)
	
	# Update Player's Icons
	player.update_side_icon(index + 1, hand[index].card_artwork)

func play_ability(ability_id: String):
	var ability_instance = CARD_ABILITIES[ability_id].instantiate()
	player.add_child(ability_instance)
	print(ability_instance)

func shuffle_deck():
	deck.shuffle()

func discard_card():
	pass

func draw_full_hand():
	pass
