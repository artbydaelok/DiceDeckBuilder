extends Node

@export var hand : Array[Card] = [null, null, null, null, null, null]
@export var deck : Array[Card]
@export var discard_pile : Array[Card]

@export var hand_display : Control

@export var player : Node

@export var global_cooldown : float = 0.8
var system_disabled = false

signal card_drawn

@export var shuffle_deck_mode : bool = false

# Match the Ability ID.
const CARD_ABILITIES = {
	"arrow" : preload("res://abilities/bow_and_arrow/bow_and_arrow.tscn"),
	"axe" : preload("res://abilities/axe_throw/axe_throw.tscn"),
	"balloon" : preload("res://abilities/balloon/balloon_pop.tscn"),
	"swipe" : preload("res://abilities/bear_swipe/bear_swipe.tscn"),
	"shotgun" : preload("res://abilities/shotgun/shotgun_blast.tscn"),
	"grenade" : preload("res://abilities/grenade/grenade.tscn")
}

const CARD_DISPLAY = preload("res://card/card_display.tscn")

func _ready() -> void:
	# Test Draw At Start
	shuffle_deck()
	for i in range(6):
		draw_card(i)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("use_ability") and not player.rolling:
		play_ability()
		
func draw_card(index: int):
	# If deck is empty, shuffle the discard pile into the deck.
	if deck.size() == 0:
		shuffle_discard_into_deck()
	
	# Move card from deck to hand.
	var card_to_draw = deck[0]
	#hand.insert(index, card_to_draw)
	hand[index] = card_to_draw
	deck.remove_at(0)
	
	if hand_display != null:
		if hand_display.get_child(player.up_side).animation_player.is_playing():
			await hand_display.get_child(player.up_side).animation_player.animation_finished
		
		# Update the UI
		hand_display.update_index(index, card_to_draw)
	
	# Update Player's Icons
	player.update_side_icon(index + 1, hand[index].card_artwork)
	
	card_drawn.emit()

func play_ability():
	if player.input_disabled: return
	if system_disabled == true: return
	
	if hand[player.up_side].cost > player.energy: 
		player.insufficient_energy.emit()
		return
	
	system_disabled = true
	
	# Gets the ability ID and instantiates it.
	var id = hand[player.up_side].ability_id
	if id == "empty":
		return
	var ability_instance = CARD_ABILITIES[id].instantiate()
	player.add_child(ability_instance)
	
	player.begin_attack_commit(hand[player.up_side].commit_value)
	
	var _cost = hand[player.up_side].cost
	player.energy -= _cost
	player.energy = clamp(player.energy, 0, 6)
	player.energy_spent.emit(_cost)
	
	if hand_display != null:
		# This triggers the animations for the Card UI Element
		hand_display.on_played_card(player.up_side)
	
	if shuffle_deck_mode:
		# Using the index, we determine which card to discard in the arrays.
		discard_card(player.up_side)
	
	await get_tree().create_timer(global_cooldown).timeout
	system_disabled = false

func shuffle_deck():
	deck.shuffle()

func discard_card(index : int):
	# Adds it to the discard pile array
	discard_pile.append(hand[index])
	
	# After discarding the played card, replace it.
	draw_card(index)

func shuffle_discard_into_deck():
	deck = discard_pile
	shuffle_deck()
	discard_pile = []
