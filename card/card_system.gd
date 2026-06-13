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

# ── Charge (hold-to-charge inputs) ──
## Emitted while a chargeable input is held — for UI such as a charge bar.
signal charge_started(secondary: bool)
signal charge_changed(seconds: float)
signal charge_ended
## Max seconds of charge tracked (safety cap).
const MAX_CHARGE_TIME := 1.5
var _charging : bool = false
var _charge_secondary : bool = false
var _charge_time : float = 0.0
## The ability spawned on press (held), loosed on release.
var _charging_instance : Node = null

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
	if player.rolling or player.input_disabled or deck_mode_active:
		_cancel_charge()
		return

	# Accumulate charge while a chargeable input is held.
	if _charging:
		_charge_time = min(_charge_time + delta, MAX_CHARGE_TIME)
		charge_changed.emit(_charge_time)
		# Drive the held ability's charge visual (e.g. the bow draw) from the charge.
		if is_instance_valid(_charging_instance) and _charging_instance.has_method("set_charge_progress"):
			_charging_instance.set_charge_progress(_charge_time)

	# Primary (top face): charge on hold if chargeable, else fire on press.
	if Input.is_action_just_pressed("use_ability"):
		if _input_is_chargeable(false):
			_begin_charge(false)
		else:
			play_ability()
	elif Input.is_action_just_released("use_ability") and _charging and not _charge_secondary:
		_fire_charged()

	# Secondary (top face).
	if Input.is_action_just_pressed("use_ability_secondary"):
		if _input_is_chargeable(true):
			_begin_charge(true)
		else:
			play_ability_secondary()
	elif Input.is_action_just_released("use_ability_secondary") and _charging and _charge_secondary:
		_fire_charged()

	# Side faces always fire instantly (shoulder buttons).
	if Input.is_action_just_pressed("use_left_side"):
		play_ability_for_side("left")
	if Input.is_action_just_pressed("use_right_side"):
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
	

## Fires the top face's PRIMARY ability (main action button — LMB / A).
func play_ability() -> void:
	play_ability_for_slot(player.up_side, false)

## Fires the top face's SECONDARY ability (secondary button — RMB / B).
func play_ability_secondary() -> void:
	play_ability_for_slot(player.up_side, true)

## Fires a manually-activatable ability in a specific hand slot (0–5).
## secondary=false uses the card's primary ability_id; secondary=true uses its
## secondary_ability_id. Shared by the action button, the secondary button, and
## the side-face shoulder buttons (which fire the primary).
func play_ability_for_slot(slot: int, secondary: bool = false, charge: float = 0.0) -> void:
	if deck_mode_active: return  # deck sides are puzzle inputs, not abilities
	if player.input_disabled: return
	if system_disabled: return
	if slot < 0 or slot >= hand.size(): return
	if hand[slot] == null: return
	var item: Card = hand[slot]

	var ability_id: String = item.secondary_ability_id if secondary else item.ability_id
	if ability_id.is_empty():
		return  # no secondary defined (or empty primary)

	if not secondary:
		# Primary press: only ACTIVATE and BOTH cards respond.
		if item.trigger_type == Card.TriggerType.ON_FACE_UP: return
		if item.trigger_type == Card.TriggerType.LINKED: return

	# Shotgun is a stateful weapon: it can't fire while spent (no spammed pellets),
	# and reloading does nothing while already loaded. Bail BEFORE spending energy.
	if ability_id == "shotgun":
		if not secondary and not player.shotgun_loaded: return
		if secondary and player.shotgun_loaded: return

	# Bear Trap release does nothing (and costs nothing) with an empty trap.
	if ability_id == "bear_trap" and secondary and player.captured_creature.is_empty():
		return

	# Fan the Hammer needs a loaded revolver.
	if ability_id == "revolver" and secondary and not is_instance_valid(player.active_revolver):
		return

	var ability_cost: int = item.secondary_cost if secondary else item.cost
	var commit: float = item.secondary_commit_value if secondary else item.commit_value
	# Grenade C4: detonating an already-planted charge is free (you paid to plant it).
	if ability_id == "grenade" and secondary and is_instance_valid(player.active_c4):
		ability_cost = 0
	if not energy_component.has_enough(ability_cost):
		energy_component.insufficient.emit()
		return
	energy_component.spend(ability_cost)
	_fire_ability(slot, ability_id, true, commit, secondary, charge)

## Fires the ability on a named dice face — "left", "right", "front", "back",
## "top", or "bottom" — by resolving the face to its hand slot. Used by the
## shoulder buttons to activate side faces without rolling them to the top.
func play_ability_for_side(side_key: String) -> void:
	var face_num: int = int(player.faces.get(side_key, 0))  # 1–6, 0 = unknown
	if face_num <= 0: return
	play_ability_for_slot(face_num - 1)


# ── Charge helpers ────────────────────────────────────────────────────────────

## True if the top card's chosen input charges on hold instead of firing on press.
func _input_is_chargeable(secondary: bool) -> bool:
	var slot: int = player.up_side
	if slot < 0 or slot >= hand.size() or hand[slot] == null:
		return false
	var item: Card = hand[slot]
	return item.secondary_chargeable if secondary else item.chargeable

## Press: spawn the ability now, in a held/charging state. It loosens on release.
func _begin_charge(secondary: bool) -> void:
	if _charging:
		return
	var slot: int = player.up_side
	if slot < 0 or slot >= hand.size() or hand[slot] == null:
		return
	var item: Card = hand[slot]
	var ability_id: String = item.secondary_ability_id if secondary else item.ability_id
	if ability_id.is_empty() or not CARD_ABILITIES_SCENES.has(ability_id):
		return
	if not secondary:
		if item.trigger_type == Card.TriggerType.ON_FACE_UP: return
		if item.trigger_type == Card.TriggerType.LINKED: return

	_charging = true
	_charge_secondary = secondary
	_charge_time = 0.0

	var inst = CARD_ABILITIES_SCENES[ability_id].instantiate()
	if "card_system" in inst:
		inst.card_system = self
	if "is_secondary" in inst:
		inst.is_secondary = secondary
	if "is_charging" in inst:
		inst.is_charging = true
	_charging_instance = inst
	player.add_child(inst)
	charge_started.emit(secondary)

func _cancel_charge() -> void:
	if not _charging:
		return
	_charging = false
	charge_ended.emit()
	_discard_charging_instance()

## Release: spend energy + commit, then tell the held ability to fire with the charge time.
func _fire_charged() -> void:
	var secondary: bool = _charge_secondary
	var charge_seconds: float = _charge_time
	_charging = false
	charge_ended.emit()

	var inst = _charging_instance
	_charging_instance = null
	if not is_instance_valid(inst):
		return

	var slot: int = player.up_side
	if slot < 0 or slot >= hand.size() or hand[slot] == null:
		_kill_instance(inst)
		return
	var item: Card = hand[slot]
	var ability_cost: int = item.secondary_cost if secondary else item.cost
	if not energy_component.has_enough(ability_cost):
		energy_component.insufficient.emit()
		_kill_instance(inst)
		return
	energy_component.spend(ability_cost)
	player.begin_attack_commit(item.secondary_commit_value if secondary else item.commit_value)

	if "charge" in inst:
		inst.charge = charge_seconds
	if inst.has_method("on_charge_release"):
		inst.on_charge_release()
	else:
		_kill_instance(inst)

func _discard_charging_instance() -> void:
	var inst = _charging_instance
	_charging_instance = null
	_kill_instance(inst)

func _kill_instance(inst) -> void:
	if is_instance_valid(inst):
		if inst.has_method("on_charge_cancel"):
			inst.on_charge_cancel()
		else:
			inst.queue_free()


func _on_roll_finished() -> void:
	player.shotgun_loaded = true  # moving reloads the shotgun
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
func _fire_ability(slot: int, ability_id: String, use_commit: bool, commit_override: float = -1.0, is_secondary: bool = false, charge: float = 0.0) -> void:
	var item: Card = hand[slot]
	if item == null: return
	if ability_id.is_empty() or ability_id == "empty": return
	if not CARD_ABILITIES_SCENES.has(ability_id): return

	system_disabled = true

	var ability_instance = CARD_ABILITIES_SCENES[ability_id].instantiate()
	# Inject self so abilities can call fire_linked_slot() for synergy chains.
	if "card_system" in ability_instance:
		ability_instance.card_system = self
	# Tell the ability which input fired it (set before _ready so initialize() sees it).
	if "is_secondary" in ability_instance:
		ability_instance.is_secondary = is_secondary
	if "charge" in ability_instance:
		ability_instance.charge = charge
	player.add_child(ability_instance)

	if use_commit:
		var commit_time: float = commit_override if commit_override >= 0.0 else item.commit_value
		player.begin_attack_commit(commit_time)

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
