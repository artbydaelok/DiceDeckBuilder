extends Node
class_name CardSystem

## Should always have 6 items, even if they're null or empty cards.
@export var hand : Array[Card] = [null, null, null, null, null, null]
## Has all of the items that are not currently in hand.
@export var deck : Array[Card]
## Currently only used when shuffle deck mode is acivated.
@export var discard_pile : Array[Card]

@export var hand_display : Control

@export var player : Node
@export var energy_component: EnergyComponent

@export var global_cooldown : float = 0.8
var system_disabled = false

signal card_drawn
signal item_used(card: Card)
signal card_slotted(card:Card, slot:int)
## Emitted when the player picks up a new card (hand slot or deck).
signal item_obtained(card: Card)

# This is just for the Ability Sides Display UI element
signal inventory_updated

@export var shuffle_deck_mode : bool = false

var held_hand : Array[Card] = []

const EMPTY_CARD = preload("uid://csjbw5er3lqoq")

# Match the Ability ID.
const CARD_ABILITIES_SCENES = {
	"arrow" : preload("res://abilities/bow_and_arrow/bow_and_arrow.tscn"),
	"axe" : preload("res://abilities/axe_throw/axe_throw.tscn"),
	"balloon" : preload("res://abilities/balloon/balloon_pop.tscn"),
	"swipe" : preload("res://abilities/bear_swipe/bear_swipe.tscn"),
	"shotgun" : preload("res://abilities/shotgun/shotgun_blast.tscn"),
	"revolver" : preload("uid://wddmnlowa6eo"),
	"grenade" : preload("res://abilities/grenade/grenade.tscn"),
	"map" : preload("uid://d0xc0g8xk7mqx"),
	"bear_trap" : preload("uid://eia6jn7jy42a"),
	"lantern" : preload("uid://7wyhdau62bhk")
}

const CARD_ABILITIES_RESOURCES = {
	"arrow" : preload("res://card/card_abilities/arrow.tres"),
	"axe" : preload("res://card/card_abilities/axe_throw.tres"),
	"balloon" : preload("res://card/card_abilities/balloon_pop.tres"),
	"swipe" : preload("res://card/card_abilities/bear_swipe.tres"),
	"shotgun" : preload("res://card/card_abilities/shotgun.tres"),
	"revolver" : preload("uid://cxkhpti5iqlnb"),
	"grenade" : preload("res://card/card_abilities/grenade.tres"),
	"map" : preload("uid://d2ovjhng2ojsa"),
	"bear_trap" : preload("uid://v0v5lgovq8xw"),
	"lantern" : preload("uid://m6x4ffngkvk4")
}

const COLOR_CARDS = [
	preload("uid://c7ffy6x5xuo0g"), # BLUE
	preload("uid://u5x4au7pxbto"), # GREEN
	preload("uid://o4dmv07j8qu2"), # PINK
	preload("uid://5tknsxey7rk6"), # RED
	preload("uid://b1d1pyfoo5cm6"), # WHITE
	preload("uid://cgiirlpt7ksns") # YELLOW
]

const CARD_DISPLAY = preload("res://card/card_display.tscn")

func _ready() -> void:
	# Test Draw At Start
	shuffle_deck()

	## THIS DRAWS 6 items
	#for i in range(6):
		#draw_card(i)

	_save_system_load_player_data()

	load_hand.call_deferred()

	player.roll_finished.connect(_on_roll_finished)
	
func load_hand():
	for i in range(hand.size()):
		var card : Card = hand[i]
		if card != null:
			player.update_side_icon(i + 1, card.card_artwork)

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
	
	#if hand_display != null:
		#if hand_display.get_child(player.up_side).animation_player.is_playing():
			#await hand_display.get_child(player.up_side).animation_player.animation_finished
		#
		## Update the UI
		#hand_display.update_index(index, card_to_draw)
	
	# Update Player's Icons
	player.update_side_icon(index + 1, hand[index].card_artwork)
	
	card_drawn.emit()

func set_slot_to_item(slot: int, card: Card):
	hand[slot] = card
	if card == null:
		player.update_side_icon(slot + 1, EMPTY_CARD.card_artwork)
	else:
		player.update_side_icon(slot + 1, card.card_artwork)
		
	card_slotted.emit(card, slot)
	inventory_updated.emit()
	
	update_save_file()

func get_slot_from_item(item: Card) -> int:
	var equipped_items : Array = hand
	var result := equipped_items.find(item)
	return result

func obtain_new_item(item: Card):
	item_obtained.emit(item)

	# Prefer the current top face if it's empty.
	var top: int = player.up_side
	if hand[top] == null:
		set_slot_to_item(top, item)
		return

	# Otherwise pick a random empty slot.
	var empty_slots: Array[int] = []
	for i in range(hand.size()):
		if hand[i] == null:
			empty_slots.append(i)

	if not empty_slots.is_empty():
		set_slot_to_item(empty_slots[randi() % empty_slots.size()], item)
		return

	# Hand is full — overflow to deck.
	deck.append(item)
	

func play_ability() -> void:
	if player.input_disabled: return
	if system_disabled: return
	var slot: int = player.up_side
	if hand[slot] == null: return
	var item: Card = hand[slot]
	# Only ACTIVATE and BOTH cards respond to manual button press.
	if item.trigger_type == Card.TriggerType.ON_FACE_UP: return
	if item.trigger_type == Card.TriggerType.LINKED: return
	if not energy_component.has_enough(item.cost):
		energy_component.insufficient.emit()
		return
	energy_component.spend(item.cost)
	_fire_ability(slot, item.ability_id, true)


func _on_roll_finished() -> void:
	var slot: int = player.up_side
	if hand[slot] == null: return
	var item: Card = hand[slot]
	# ON_FACE_UP and BOTH cards trigger automatically after a roll.
	if item.trigger_type != Card.TriggerType.ON_FACE_UP and item.trigger_type != Card.TriggerType.BOTH:
		return
	if system_disabled: return
	if item.passive_ability_id.is_empty(): return
	_fire_ability(slot, item.passive_ability_id, false)


## Fires an ability by ID on behalf of the given slot.
## use_commit: whether to lock the player during the ability (passive triggers skip this).
func _fire_ability(slot: int, ability_id: String, use_commit: bool) -> void:
	var item: Card = hand[slot]
	if item == null: return
	if ability_id.is_empty() or ability_id == "empty": return
	if not CARD_ABILITIES_SCENES.has(ability_id): return

	system_disabled = true

	var ability_instance = CARD_ABILITIES_SCENES[ability_id].instantiate()
	# Inject self so abilities can call fire_linked_slot() for synergy chains.
	if "card_system" in ability_instance:
		ability_instance.card_system = self
	player.add_child(ability_instance)

	if use_commit:
		player.begin_attack_commit(item.commit_value)

	item_used.emit(item)

	if hand_display != null:
		hand_display.on_played_card(slot)

	if shuffle_deck_mode:
		discard_card(slot)

	await get_tree().create_timer(global_cooldown).timeout
	system_disabled = false

## Activates a LINKED card in the given hand slot without energy cost.
## Call this from an ability script that has a card_system reference.
func fire_linked_slot(slot: int) -> void:
	if slot < 0 or slot >= hand.size(): return
	if hand[slot] == null: return
	var item: Card = hand[slot]
	if item.trigger_type != Card.TriggerType.LINKED: return
	if item.ability_id.is_empty(): return
	_fire_ability(slot, item.ability_id, false)


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

func replace_hand(new_hand: Array[Card]):
	hold_hand()
	for i in range(6):
		set_slot_to_item(i, new_hand[i])

func hold_hand() -> Array[Card]:
	held_hand = hand
	return held_hand
	
func start_color_mode():
	replace_hand(COLOR_CARDS)

func clear_inventory():
	for i in range(hand.size()):
		set_slot_to_item(i , null)
	deck = []
	discard_pile = []
	update_save_file()

func update_save_file():
	_save_system_save_player_data()
	
#IDEA Gem Matching Levels 
#Where player needs to switch to the correct color side to defeat enemies while trying to get to the end.

#IDEA Spaceship Fight
#1: Missile
#2: Shields
#3: Missile
#4: Shields
#5: Roll Left
#6: Roll Right

func _save_system_save_player_data() -> void:
	SaveSystem.player_data.equipped_cards = hand
	SaveSystem.player_data.inventory_cards = deck
	SaveSystem.save_player_data()

func _save_system_load_player_data() -> void:
	hand = SaveSystem.player_data.equipped_cards
	deck = SaveSystem.player_data.inventory_cards
	print("_on_save_system_update_player_data")
