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

## Emitted while a puzzle Deck is active — fires after every roll with the new
## top face's value (see get_top_face_value). Puzzle scripts connect to this.
signal deck_top_changed(value: String)

@export var shuffle_deck_mode : bool = false

# ── Deck mode (temporary puzzle loadouts) ──
## True while a Deck has replaced the player's faces. While active, the live hand
## is decoupled from the save so nothing the deck does persists.
var deck_mode_active : bool = false
var _active_deck : Deck = null
## The player's real hand, stashed in memory while a deck is equipped.
var _stored_hand : Array[Card] = []

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
	if player.rolling:
		return
	if Input.is_action_just_pressed("use_ability"):
		play_ability()
	elif Input.is_action_just_pressed("use_left_side"):
		play_ability_for_side("left")
	elif Input.is_action_just_pressed("use_right_side"):
		play_ability_for_side("right")
		
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
	GameEvents.card_equipped.emit(card, slot)

	update_save_file()

func get_slot_from_item(item: Card) -> int:
	var equipped_items : Array = hand
	var result := equipped_items.find(item)
	return result

func obtain_new_item(item: Card):
	# During a puzzle deck, route pickups into the real (preserved) hand/inventory
	# so they aren't lost and never appear on the puzzle faces.
	if deck_mode_active:
		for i in range(_stored_hand.size()):
			if _stored_hand[i] == null:
				_stored_hand[i] = item
				return
		deck.append(item)
		return

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
	

## Fires the top face's manually-activatable ability (the main action button).
func play_ability() -> void:
	play_ability_for_slot(player.up_side)

## Fires the manually-activatable ability in a specific hand slot (0–5).
## Shared by the top-face button and the side-face shoulder buttons.
func play_ability_for_slot(slot: int) -> void:
	if deck_mode_active: return  # deck sides are puzzle inputs, not abilities
	if player.input_disabled: return
	if system_disabled: return
	if slot < 0 or slot >= hand.size(): return
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

## Fires the ability on a named dice face — "left", "right", "front", "back",
## "top", or "bottom" — by resolving the face to its hand slot. Used by the
## shoulder buttons to activate side faces without rolling them to the top.
func play_ability_for_side(side_key: String) -> void:
	var face_num: int = int(player.faces.get(side_key, 0))  # 1–6, 0 = unknown
	if face_num <= 0: return
	play_ability_for_slot(face_num - 1)


func _on_roll_finished() -> void:
	if deck_mode_active:
		deck_top_changed.emit(get_top_face_value())
		return
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

# ── Deck mode API ──────────────────────────────────────────────────────────────

## Swap the player's six faces for a temporary puzzle Deck. The real hand is
## stashed in memory and the save is decoupled, so nothing the deck does persists.
## Call clear_deck() to restore. Safe to call again to swap deck-for-deck.
func equip_deck(deck_resource: Deck) -> void:
	if deck_resource == null or deck_resource.sides.size() < 6:
		push_warning("equip_deck: deck is null or has fewer than 6 sides")
		return

	# Only stash the real hand the first time (re-equipping swaps deck-for-deck).
	if not deck_mode_active:
		_stored_hand = hand.duplicate()
		# Point the save at the preserved real hand so a mid-puzzle save (e.g. a
		# coin pickup) can never serialise the puzzle deck.
		SaveSystem.player_data.equipped_cards = _stored_hand

	deck_mode_active = true
	_active_deck = deck_resource
	# Give the live hand its OWN array of the deck's sides (never mutate the resource).
	hand = deck_resource.sides.duplicate()
	_apply_face_icons()
	deck_top_changed.emit(get_top_face_value())

## Restore the player's real hand and leave deck mode.
func clear_deck() -> void:
	if not deck_mode_active:
		return
	deck_mode_active = false
	_active_deck = null
	hand = _stored_hand
	SaveSystem.player_data.equipped_cards = hand
	_stored_hand = []
	_apply_face_icons()

## The puzzle-meaning of the current top face ("blue", "hearts", "up", …).
## Falls back to the card's ability_id, then "" for an empty/unknown face.
func get_top_face_value() -> String:
	var slot: int = player.up_side
	if slot < 0 or slot >= hand.size() or hand[slot] == null:
		return ""
	var card: Card = hand[slot]
	return card.face_value if card.face_value != "" else card.ability_id

## Repaints the six dice-face sprites from the current hand. Save-free and
## signal-free (does NOT go through set_slot_to_item), so deck swaps never persist
## or fire card_equipped / quest progress.
func _apply_face_icons() -> void:
	for i in range(6):
		var card: Card = hand[i] if i < hand.size() else null
		if card == null:
			player.update_side_icon(i + 1, EMPTY_CARD.card_artwork)
		else:
			player.update_side_icon(i + 1, card.card_artwork)
	inventory_updated.emit()

func clear_inventory():
	for i in range(hand.size()):
		set_slot_to_item(i , null)
	deck = []
	discard_pile = []
	update_save_file()

func update_save_file():
	if deck_mode_active:
		return  # never persist a temporary puzzle deck
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
